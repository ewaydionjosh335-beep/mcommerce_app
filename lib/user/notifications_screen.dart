import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e, s) {
      logError('Notifications', e, s);
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e, s) {
      logError('Notifications', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    // Only fetch this user's notifications + admin broadcasts ('all').
    // Needs the composite index: userId (Asc) + timestamp (Desc).
    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', whereIn: [user.uid, 'all'])
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] as String?) ?? 'Notification';
              final body = (data['body'] as String?) ?? '';
              final type = (data['type'] as String?) ?? 'order';
              final isBroadcast = data['userId'] == 'all';
              // Broadcasts are shared by everyone, so users can't mark/delete them.
              final isRead = isBroadcast ? true : ((data['isRead'] as bool?) ?? false);
              final timestamp = data['timestamp'] as Timestamp?;
              final timeStr = timestamp != null
                  ? timestamp.toDate().toString().substring(0, 16)
                  : 'Just now';

              final icon = type == 'promo'
                  ? Icons.local_offer_outlined
                  : Icons.receipt_long_outlined;

              return Dismissible(
                key: ValueKey(doc.id),
                direction: isBroadcast
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNotification(doc.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isRead ? 1 : 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isRead ? Colors.white : Colors.indigo.shade50.withValues(alpha: 0.6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: type == 'promo' ? Colors.orange.shade100 : Colors.indigo.shade100,
                      child: Icon(icon, color: type == 'promo' ? Colors.orange.shade800 : Colors.indigo.shade800),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(body, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                    onTap: () {
                      if (!isRead && !isBroadcast) {
                        _markAsRead(doc.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}