import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.verified({String label = 'Verified'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF2E7D32),
      icon: Icons.verified,
    );
  }

  factory StatusBadge.pending({String label = 'Pending Verification'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFFFF3E0),
      textColor: const Color(0xFFE65100),
      icon: Icons.hourglass_empty,
    );
  }

  factory StatusBadge.rejected({String label = 'Rejected'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFFFEBEE),
      textColor: const Color(0xFFC62828),
      icon: Icons.cancel,
    );
  }

  factory StatusBadge.organic({String label = 'Organic'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF1B5E20),
      icon: Icons.eco,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
