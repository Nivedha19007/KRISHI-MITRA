import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Order Status Update 🚚',
      message: 'Your order for 5 kg Country Tomato (Batch: TOM-CBE-001) has been dispatched.',
      timeAgo: '15 mins ago',
      icon: Icons.local_shipping,
      color: AppColors.primaryGreen,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Community Reply 💬',
      message: 'Meena Patil replied to your post "Country Tomato leaf yellowing advice".',
      timeAgo: '1 hour ago',
      icon: Icons.forum,
      color: Colors.orange,
    ),
    NotificationItem(
      id: 'n3',
      title: 'Mandi Price Alert 📈',
      message: 'Tomato price in Gobichettipalayam Mandi increased by ₹2/kg to ₹24/kg.',
      timeAgo: '3 hours ago',
      icon: Icons.trending_up,
      color: Colors.blue,
    ),
    NotificationItem(
      id: 'n4',
      title: 'Prediction Alert 🔮',
      message: '30-day forecast for Country Tomato shows expected 40% price surge.',
      timeAgo: '5 hours ago',
      icon: Icons.auto_graph,
      color: Colors.purple,
    ),
    NotificationItem(
      id: 'n5',
      title: 'Government Scheme Announcement 🏛️',
      message: 'PM-KISAN 17th Installment registration window is now open.',
      timeAgo: '1 day ago',
      icon: Icons.account_balance,
      color: AppColors.secondaryBrown,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications 🔔'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
              );
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.color.withOpacity(0.15),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item.message, style: const TextStyle(fontSize: 13)),
              ),
              trailing: Text(item.timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}
