import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import 'analytics_dashboard_section.dart';
import 'inventory_section.dart';
import 'orders_section.dart';
import 'product_management.dart';
import 'users_section.dart';
import 'notifications_section.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  static const _titles = ['Dashboard / Analytics', 'Products', 'Inventory', 'Orders', 'Users', 'Notifications'];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.warehouse_outlined,
    Icons.receipt_long_outlined,
    Icons.people_outline,
    Icons.notifications_outlined,
  ];

  Widget _section() {
    switch (_index) {
      case 1:
        return const ProductManagement();
      case 2:
        return const InventorySection();
      case 3:
        return const OrdersSection();
      case 4:
        return const UsersSection();
      case 5:
        return const NotificationsSection();
      default:
        return const AnalyticsDashboardSection();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSidebar({required bool inDrawer}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryColor = theme.colorScheme.primary;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.admin_panel_settings, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chopify',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                itemCount: _titles.length,
                itemBuilder: (context, i) {
                  final selected = _index == i;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: selected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(
                          _icons[i],
                          color: selected ? primaryColor : textColor.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        title: Text(
                          _titles[i],
                          style: TextStyle(
                            color: selected ? primaryColor : textColor.withValues(alpha: 0.8),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _index = i);
                          if (inDrawer) Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode', style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                    secondary: Icon(Icons.dark_mode_outlined, color: textColor.withValues(alpha: 0.8), size: 20),
                    value: context.watch<ThemeProvider>().isDarkMode,
                    onChanged: (val) {
                      context.read<ThemeProvider>().setTheme(val);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.logout_outlined, color: AppColors.danger, size: 20),
                      title: const Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final content = Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: _section(),
        );

        if (wide) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 260, child: _buildSidebar(inDrawer: false)),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: content,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_index]),
          ),
          drawer: SizedBox(width: 280, child: Drawer(child: _buildSidebar(inDrawer: true))),
          body: content,
        );
      },
    );
  }
}
