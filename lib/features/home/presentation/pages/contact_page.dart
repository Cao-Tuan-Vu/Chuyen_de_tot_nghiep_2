import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  static const String routeName = '/contact';

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final String subject = _subjectController.text.trim();
    final String body = _messageController.text.trim();

    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!')),
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '20220249@gmail.com',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        _subjectController.clear();
        _messageController.clear();
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở ứng dụng email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Liên Hệ', 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.indigo, Colors.indigoAccent],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withAlpha((0.05 * 255).round()),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.contact_support_rounded, size: 80, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Thông tin cá nhân', isDarkMode),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    isDarkMode,
                    icon: Icons.person_rounded,
                    title: 'Họ tên',
                    value: 'Ta Phuc Anh',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    context,
                    isDarkMode,
                    icon: Icons.phone_rounded,
                    title: 'Số điện thoại',
                    value: '0769743204',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    context,
                    isDarkMode,
                    icon: Icons.email_rounded,
                    title: 'Email',
                    value: '20220249@gmail.com',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, 'Gửi tin nhắn phản hồi', isDarkMode),
                  const SizedBox(height: 16),
                  _buildFeedbackForm(context, isDarkMode),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, bool isDarkMode,
      {required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
            BoxShadow(
             color: Colors.black.withAlpha(((isDarkMode ? 0.3 : 0.05) * 255).round()),
             blurRadius: 15,
             offset: const Offset(0, 8),
           ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
               color: color.withAlpha((0.1 * 255).round()),
               borderRadius: BorderRadius.circular(15),
             ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
           Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.withAlpha((0.5 * 255).round())),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm(BuildContext context, bool isDarkMode) {
    final fieldColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _subjectController,
            label: 'Tiêu đề',
            icon: Icons.subject_rounded,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _messageController,
            label: 'Nội dung phản hồi',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 4,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _sendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Gửi Tin Nhắn', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label, 
    required IconData icon, 
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.indigo, size: 22),
        filled: true,
        fillColor: isDarkMode ? Colors.black.withAlpha((0.3 * 255).round()) : Colors.grey[50],
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
      ),
    );
  }
}
