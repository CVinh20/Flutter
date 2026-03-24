// lib/screens/profile/favorite_services_screen.dart
import 'package:flutter/material.dart';
import '../../models/service.dart';
import '../../services/data_service.dart';
import '../booking_screen.dart';

class FavoriteServicesScreen extends StatefulWidget {
  const FavoriteServicesScreen({super.key});

  @override
  State<FavoriteServicesScreen> createState() => _FavoriteServicesScreenState();
}

class _FavoriteServicesScreenState extends State<FavoriteServicesScreen> {
  final DataService _dataService = DataService();
  List<Service> _favoriteServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final favorites = await _dataService.getFavoriteServices();
      if (mounted) {
        setState(() {
          _favoriteServices = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFavorite(Service service) async {
    try {
      await _dataService.toggleFavoriteService(service.id);
      if (mounted) {
        setState(() {
          _favoriteServices.removeWhere((s) => s.id == service.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${service.name}" khỏi yêu thích'),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0891B2)))
          : _favoriteServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border, size: 80, color: Color(0xFF0891B2)),
                      ),
                      const SizedBox(height: 24),
                      const Text('Chưa có dịch vụ yêu thích', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _favoriteServices.length,
                  itemBuilder: (context, index) {
                    final service = _favoriteServices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(service: service))),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(service.image, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 64))),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                                      onPressed: () => _removeFavorite(service),
                                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(service.description, style: TextStyle(color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text('${service.duration} phút', style: const TextStyle(color: Color(0xFF0891B2), fontWeight: FontWeight.w600)),
                                        const Spacer(),
                                        Text('${service.price.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0891B2))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
