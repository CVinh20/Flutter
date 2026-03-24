// lib/screens/services_screen.dart
import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import 'booking_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  late TabController _tabController;
  List<Category> _categories = [];
  List<Service> _allServices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load categories and services
      final categories = await _dataService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _tabController = TabController(length: _categories.length + 1, vsync: this);
        });
      }

      final services = await _dataService.getServices();
      if (mounted) {
        setState(() {
          _allServices = services;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dịch vụ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0891B2),
        elevation: 0,
        bottom: _categories.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  const Tab(text: 'Tất cả'),
                  ..._categories.map((category) => Tab(text: category.name)),
                ],
              )
            : null,
      ),
      body: _categories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildServicesGrid(_getAllServices()),
                ..._categories.map((category) => 
                    _buildServicesGrid(_getServicesByCategory(category.id))),
              ],
            ),
    );
  }

  Widget _buildServicesGrid(List<Service> services) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dịch vụ nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => _navigateToBooking(service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0891B2).withOpacity(0.1),
                        const Color(0xFF0891B2).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: service.image.isNotEmpty
                      ? Image.network(
                          service.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.build_circle_outlined,
                                size: 48,
                                color: Color(0xFF0891B2),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.build_circle_outlined,
                            size: 48,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                ),
              ),
            ),
            
            // Service Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.rating.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
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
      ),
    );
  }

  List<Service> _getServicesByCategory(String categoryId) {
    return _allServices.where((service) => service.categoryId == categoryId).toList();
  }

  List<Service> _getAllServices() {
    return _allServices;
  }

  void _navigateToBooking(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(),
        settings: RouteSettings(arguments: service),
      ),
    );
  }
}
