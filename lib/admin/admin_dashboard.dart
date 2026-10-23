import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../providers/theme_provider.dart';
import 'analytics_dashboard_section.dart';
import 'inventory_section.dart';
import 'orders_section.dart';
import 'product_management.dart';
import 'users_section.dart';
import 'notifications_section.dart';

// HOA04 Step 1: Dashboard layout (sidebar + Analytics / Products / Inventory / Orders / Users / Notifications sections)
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

  // Sidebar: permanent on wide screens, inside a Drawer on narrow screens
  Widget _buildSidebar({required bool inDrawer}) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Material(
      color: primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, color: onPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_icons[i]),
                title: Text(_titles[i]),
                selected: _index == i,
                iconColor: onPrimary.withValues(alpha: 0.7),
                textColor: onPrimary.withValues(alpha: 0.7),
                selectedColor: onPrimary,
                selectedTileColor: onPrimary.withValues(alpha: 0.2),
                onTap: () {
                  setState(() => _index = i);
                  if (inDrawer) Navigator.pop(context);
                },
              ),
             const Spacer(),
            SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(color: onPrimary.withValues(alpha: 0.7), fontSize: 14)),
              secondary: Icon(Icons.dark_mode_outlined, color: onPrimary.withValues(alpha: 0.7)),
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (val) {
                context.read<ThemeProvider>().setTheme(val);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Logout'),
              iconColor: onPrimary.withValues(alpha: 0.7),
              textColor: onPrimary.withValues(alpha: 0.7),
              onTap: _logout,
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
        final wide = constraints.maxWidth >= 800;

        final content = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide) ...[
                Text(
                  _titles[_index],
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(child: _section()),
            ],
          ),
        );

        if (wide) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 240, child: _buildSidebar(inDrawer: false)),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_titles[_index])),
          drawer: Drawer(child: _buildSidebar(inDrawer: true)),
          body: content,
        );
      },
    );
  }
}