import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const String routeName = '/contact';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liên Hệ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liên Hệ Chúng Tôi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'support@btl-learning.com',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: 'Điện Thoại',
                    subtitle: '(+84) 28 3000 0000',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.location_on_outlined,
                    title: 'Địa Chỉ',
                    subtitle: 'TP. Hồ Chí Minh, Việt Nam',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.access_time_outlined,
                    title: 'Giờ Làm Việc',
                    subtitle: 'Thứ 2 - Thứ 6: 9:00 - 18:00',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gửi Tin Nhắn',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tên của bạn',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      prefixIcon: Icon(Icons.subject_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Tin nhắn',
                      prefixIcon: Icon(Icons.message_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cảm ơn bạn! Chúng tôi sẽ phản hồi sớm.')),
                      );
                    },
                    child: const Text('Gửi Tin Nhắn'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theo Dõi Chúng Tôi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.public),
                        tooltip: 'Website',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook),
                        tooltip: 'Facebook',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.camera_alt_outlined),
                        tooltip: 'Instagram',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'Chat',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

