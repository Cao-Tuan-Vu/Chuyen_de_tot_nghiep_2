import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  static const String routeName = '/policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính Sách & Điều Khoản'),
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
                    'Điều Khoản Dịch Vụ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Chấp Thuận Sử Dụng',
                    'Bằng cách sử dụng BTL Learning, bạn đồng ý tuân theo các điều khoản và chính sách này. Nếu bạn không đồng ý với bất kỳ phần nào, vui lòng không sử dụng dịch vụ của chúng tôi.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Trách Nhiệm Người Dùng',
                    'Bạn chịu trách nhiệm duy trì mật độ bảo mật của tài khoản của mình. Không được phép chia sẻ tài khoản với người khác. Bạn chịu trách nhiệm về tất cả các hoạt động xảy ra dưới tài khoản của bạn.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Nội Dung Học Tập',
                    'Tất cả nội dung học tập, bài giảng, quiz và tài liệu được cung cấp bởi BTL Learning. Bạn có quyền sử dụng cho mục đích cá nhân, không được phép sao chép hay phân phối mà không có sự cho phép.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Giới Hạn Trách Nhiệm',
                    'BTL Learning cung cấp dịch vụ trên cơ sở "hiện trạng". Chúng tôi không bảo đảm độ chính xác, tính khả dụng hoặc tính phù hợp của dịch vụ cho mục đích cụ thể của bạn.',
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
                    'Chính Sách Bảo Mật',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Thông Tin Chúng Tôi Thu Thập',
                    'Chúng tôi thu thập thông tin bạn cung cấp khi đăng ký, bao gồm: email, tên hiển thị, mật khẩu. Chúng tôi cũng thu thập dữ liệu sử dụng ứng dụng để cải thiện dịch vụ.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Cách Chúng Tôi Sử Dụng Dữ Liệu',
                    'Dữ liệu của bạn được sử dụng để: cung cấp dịch vụ, gửi thông báo, phân tích sử dụng, cải thiện trải nghiệm người dùng. Chúng tôi không bao giờ bán dữ liệu của bạn cho bên thứ ba.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Bảo Vệ Dữ Liệu',
                    'Chúng tôi sử dụng các biện pháp bảo mật tiêu chuẩn để bảo vệ thông tin của bạn khỏi truy cập trái phép, thay đổi, tiết lộ hoặc hủy.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Quyền Của Bạn',
                    'Bạn có quyền truy cập, chỉnh sửa hoặc xóa dữ liệu cá nhân của mình. Liên hệ chúng tôi tại support@btl-learning.com để thực hiện.',
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
                    'Chính Sách Hoàn Tiền',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Hoàn Tiền',
                    'Nếu bạn không hài lòng với khóa học, bạn có thể yêu cầu hoàn tiền trong vòng 30 ngày kể từ khi mua. Vui lòng liên hệ với bộ phận hỗ trợ của chúng tôi.',
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Điều Kiện',
                    'Hoàn tiền chỉ được cấp nếu bạn đã học ít hơn 50% khóa học. Sau khi hoàn tiền, bạn sẽ mất quyền truy cập vào khóa học.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cập Nhật Lần Cuối',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ngày 11 tháng 4 năm 2026',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }
}

