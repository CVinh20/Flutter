import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, '30SHINE - ĐIỂM TỰA CHO VIỆC LỚN'),
            const SizedBox(height: 8),
            const Text(
              '"Hãy cho tôi một điểm tựa, tôi sẽ nâng cả thế giới." - Archimedes',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mỗi người đàn ông đều có một hành trình riêng, một thế giới muốn chinh phục...\n\n30Shine không tạo ra chúng. Chúng tôi là điểm tựa, giúp anh thể hiện trọn vẹn phong thái, khí chất và sẵn sàng cho những điều quan trọng phía trước.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network('https://i.imgur.com/vHqY7bK.png'), // Placeholder - thay bằng ảnh từ IMG_5804.jpg
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'KIỂU TÓC ĐẸP KHÔNG PHẢI ĐÍCH ĐẾN - MÀ LÀ ĐIỂM KHỞI ĐẦU'),
            const SizedBox(height: 16),
            const Text(
              'Một kiểu tóc đẹp không chỉ để ngắm nhìn – mà còn để cảm nhận:\nCảm nhận sự thoải mái, tự tin, sẵn sàng\nCảm nhận một phiên bản tốt hơn của chính mình\n\nVới gần 150 salon trên toàn quốc, công nghệ hiện đại và đội ngũ thợ tận tâm, 30Shine không chỉ mang đến một diện mạo mới. Chúng tôi giúp anh luôn trong trạng thái tốt nhất – để đón nhận bất kỳ điều gì đang chờ phía trước.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}