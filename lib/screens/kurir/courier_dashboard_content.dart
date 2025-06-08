import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class CourierDashboardContent extends StatefulWidget {
  const CourierDashboardContent({super.key});

  @override
  _CourierDashboardContentState createState() =>
      _CourierDashboardContentState();
}

class _CourierDashboardContentState extends State<CourierDashboardContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _deliveryTasks = [
    {
      'order_id': 'ORD001',
      'customer_name': 'Budi Santoso',
      'address': 'Jl. Sudirman No. 123',
      'status': 'Siap Dikirim',
      'date': '2025-06-08',
    },
    {
      'order_id': 'ORD002',
      'customer_name': 'Ani Rahayu',
      'address': 'Jl. Thamrin No. 45',
      'status': 'Sedang Dikirim',
      'date': '2025-06-07',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Fetch user profile
      final profileResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (profileData['user_type'] != 'pegawai' ||
            !profileData['user']['role'].contains('kurir')) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Akses hanya untuk kurir.';
              _isLoading = false;
            });
          }
          return;
        }

        // Fetch transactions
        final transactionsResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/kurir/transaksi-penjualan'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        int totalDeliveries = 0;
        int completedDeliveries = 0;
        if (transactionsResponse.statusCode == 200) {
          final transactions = jsonDecode(transactionsResponse.body)['data'];
          totalDeliveries = transactions.length;
          completedDeliveries =
              transactions.where((t) => t['status'] == 'Sudah Diterima').length;
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Gagal memuat data transaksi: ${transactionsResponse.statusCode}';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _dashboardData = {
              'name': profileData['user']['nama'],
              'total_deliveries': totalDeliveries,
              'completed_deliveries': completedDeliveries,
            };
            _isLoading = false;
          });
        }
      } else if (profileResponse.statusCode == 401) {
        await prefs.remove('token');
        if (mounted) {
          setState(() {
            _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat profil: ${profileResponse.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: Koneksi gagal. Silakan coba lagi. ($e)';
          _isLoading = false;
        });
      }
    }
  }

  void _updateStatus(int index) {
    setState(() {
      if (_deliveryTasks[index]['status'] == 'Siap Dikirim') {
        _deliveryTasks[index]['status'] = 'Sedang Dikirim';
      } else if (_deliveryTasks[index]['status'] == 'Sedang Dikirim') {
        _deliveryTasks[index]['status'] = 'Sudah Diterima';
        _dashboardData?['completed_deliveries'] =
            (_dashboardData?['completed_deliveries'] ?? 0) + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final oliveGreen = const Color(0xFF7A7C52);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 8,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      oliveGreen,
                      oliveGreen.withOpacity(0.9),
                      const Color(0xFF5A5D3A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                height: 140,
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Courier Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingShimmer()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 2,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BounceInDown(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: _buildWelcomeSection(),
          ),
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildStatsGrid(),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            duration: const Duration(milliseconds: 1200),
            child: _buildDeliveryTasksSection(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A7C52), Color(0xFF5A5D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_dashboardData!['name']}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your delivery tasks here.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Deliveries',
        'value': _dashboardData!['total_deliveries'],
        'icon': Icons.local_shipping,
        'color': Colors.blue,
      },
      {
        'title': 'Completed',
        'value': _dashboardData!['completed_deliveries'],
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  Widget _buildDeliveryTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A7C52),
          ),
        ),
        const SizedBox(height: 16),
        _deliveryTasks.isEmpty
            ? _buildEmptyTasks()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _deliveryTasks.length,
                itemBuilder: (context, index) {
                  final task = _deliveryTasks[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 600 + (index * 200)),
                    child: _buildDeliveryTaskCard(task, index),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyTasks() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada tugas pengiriman',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTaskCard(Map<String, dynamic> task, int index) {
    Color getStatusColor() {
      switch (task['status']) {
        case 'Siap Dikirim':
          return Colors.orange;
        case 'Sedang Dikirim':
          return Colors.blue;
        case 'Sudah Diterima':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () {
        if (task['status'] != 'Sudah Diterima') {
          _updateStatus(index);
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${task['order_id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['customer_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['address'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, stat['color'].withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(stat['icon'], color: stat['color'], size: 28),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      stat['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stat['value'].toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
