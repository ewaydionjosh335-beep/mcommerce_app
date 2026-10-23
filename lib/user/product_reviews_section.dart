import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/logger.dart';

class ProductReviewsSection extends StatefulWidget {
  final Product product;
  const ProductReviewsSection({super.key, required this.product});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  bool _hasPurchased = false;
  bool _checkingPurchase = true;

  @override
  void initState() {
    super.initState();
    _checkIfPurchased();
  }

  Future<void> _checkIfPurchased() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _checkingPurchase = false);
      return;
    }

    try {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      bool purchased = false;
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        // Only delivered orders can be reviewed
        if (data['status'] != 'delivered') continue;
        final items = data['items'] as List?;
        if (items != null) {
          for (final item in items) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map['productId'] == widget.product.id) {
              purchased = true;
              break;
            }
          }
        }
        if (purchased) break;
      }

      if (mounted) {
        setState(() {
          _hasPurchased = purchased;
          _checkingPurchase = false;
        });
      }
    } catch (e, s) {
      logError('ProductReviews', e, s);
      if (mounted) setState(() => _checkingPurchase = false);
    }
  }

  Future<void> _showAddReviewDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review')),
      );
      return;
    }

    int rating = 5;
    final commentController = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => rating = star),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review Comment',
                    hintText: 'Share your experience with this product...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter a review comment')),
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        final userName = (userDoc.data()?['name'] as String?) ??
                            user.email?.split('@').first ??
                            'Customer';

                        await FirebaseFirestore.instance.collection('reviews').add({
                          'productId': widget.product.id,
                          'userId': user.uid,
                          'userName': userName,
                          'rating': rating,
                          'comment': commentController.text.trim(),
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted successfully!')),
                        );
                      } catch (e, s) {
                        logError('ProductReviews', e, s);
                        setDialogState(() => submitting = false);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Failed to submit review')),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: widget.product.id)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Error loading reviews'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        double avgRating = 0;
        if (docs.isNotEmpty) {
          final total = docs.fold<int>(0, (acc, doc) => acc + ((doc.data()['rating'] as num?)?.toInt() ?? 0));
          avgRating = total / docs.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customer Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_checkingPurchase && _hasPurchased)
                  ElevatedButton.icon(
                    onPressed: _showAddReviewDialog,
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Rating Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < avgRating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${docs.length} reviews',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final star = 5 - index;
                        final count = docs.where((d) => ((d.data()['rating'] as num?)?.toInt() ?? 0) == star).length;
                        final percentage = docs.isEmpty ? 0.0 : count / docs.length;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$star', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.amber,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 24,
                                child: Text('$count', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_checkingPurchase && !_hasPurchased)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Note: You can write a review after your order of this product is delivered.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            // Reviews List
            if (docs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                final userName = (data['userName'] as String?) ?? 'Anonymous';
                final rating = ((data['rating'] as num?)?.toInt() ?? 5);
                final comment = (data['comment'] as String?) ?? '';
                final timestamp = data['timestamp'] as Timestamp?;
                final timeStr = timestamp != null
                    ? timestamp.toDate().toString().substring(0, 10)
                    : 'Recently';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}