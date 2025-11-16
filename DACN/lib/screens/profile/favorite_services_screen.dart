// lib/screens/profile/favorite_services_screen.dart
import 'package:flutter/material.dart';
import '../../models/service.dart';
import '../../services/firestore_service.dart';
import '../booking_screen.dart';

class FavoriteServicesScreen extends StatefulWidget {
  const FavoriteServicesScreen({super.key});

  @override
  State<FavoriteServicesScreen> createState() => _FavoriteServicesScreenState();
}

class _FavoriteServicesScreenState extends State<FavoriteServicesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _removeFavorite(Service service) async {
    await _firestoreService.toggleFavoriteService(service.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${service.name}" khỏi yêu thích'),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.white,
            onPressed: () async {
              await _firestoreService.toggleFavoriteService(service.id);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0891B2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dịch vụ yêu thích',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF06B6D4), Color(0xFF22D3EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Service>>(
        stream: _firestoreService.getFavoriteServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0891B2),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chưa có dịch vụ yêu thích',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm dịch vụ yêu thích để dễ dàng đặt lịch sau này',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final favoriteServices = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favoriteServices.length,
            itemBuilder: (context, index) {
              final service = favoriteServices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFavoriteCard(service),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Service service) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BookingScreen(),
            settings: RouteSettings(arguments: service),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Image.network(
                    service.image,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFFF8F9FA),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        size: 40,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
                
                // Service Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              service.rating.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF0891B2)),
                            const SizedBox(width: 4),
                            Text(
                              service.duration,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${service.price.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removeFavorite(service),
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Bỏ yêu thích'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookingScreen(),
                            settings: RouteSettings(arguments: service),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Đặt lịch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891B2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
}