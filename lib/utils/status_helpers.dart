import 'package:flutter/material.dart';

class StatusHelpers {
  static Color statusColor(BuildContext context, String status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'delivered':
        return dark ? Colors.green.shade400 : Colors.green.shade700;
      case 'shipped':
        return dark ? Colors.blue.shade400 : Colors.blue.shade700;
      case 'processing':
        return dark ? Colors.orange.shade400 : Colors.orange.shade700;
      case 'cancelled':
        return dark ? Colors.red.shade400 : Colors.red.shade700;
      case 'pending':
      default:
        return dark ? Colors.indigo.shade300 : Colors.indigo.shade700;
    }
  }

  static String statusLabel(String status) {
    return status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
  }
}
