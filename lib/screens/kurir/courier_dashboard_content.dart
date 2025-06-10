import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../kurir/courier_delivery_detail.dart';

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
  List<Map<String, dynamic>> _deliveryTasks = [];
  final AuthService _authService = AuthService();

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
        Uri.parse('http://192.168.154.254:8000/api/auth/profile'),
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
          Uri.parse(
              'http://192.168.154.254:8000/api/kurir/transaksi-penjualan'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        int totalDeliveries = 0;
        int completedDeliveries = 0;
        List<Map<String, dynamic>> activeDeliveries = [];

        if (transactionsResponse.statusCode == 200) {
          final transactions = jsonDecode(transactionsResponse.body)['data'];
          totalDeliveries = transactions.length;
          completedDeliveries =
              transactions.where((t) => t['status'] == 'Sudah Diterima').length;

          // Filter for active deliveries (Siap Dikirim or Sedang Dikirim)
          for (var transaction in transactions) {
            if (['Siap Dikirim', 'Sedang Dikirim']
                .contains(transaction['status'])) {
              final detailResponse = await http.get(
                Uri.parse(
                    'http://192.168.154.254:8000/api/kurir/transaksi-penjualan/${transaction['no_nota']}'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (detailResponse.statusCode == 200) {
                final detailData = jsonDecode(detailResponse.body)['data'];
                final products = detailData['products'] as List<dynamic>? ?? [];
                final items = products.map((p) {
                  final imageUrl = p['image'] != '/api/placeholder/60/60'
                      ? 'http://192.168.154.254:8000/api/products/${p['product_id']}/thumbnail'
                      : 'http://192.168.154.254:8000/api/placeholder/60/60';
                  return {
                    'name': p['nama_barang'] as String? ?? 'Unknown Item',
                    'price': p['harga_barang'] as String? ?? 'Rp0',
                    'image': imageUrl,
                    'product_id': p['product_id'] as String? ?? '',
                  };
                }).toList();

                activeDeliveries.add({
                  'id_penjualan': transaction['id_penjualan'],
                  'order_id': transaction['no_nota'] ?? 'Unknown ID',
                  'customer_name':
                      detailData['nama_pembeli'] ?? 'Unknown Buyer',
                  'address': detailData['alamat'] ?? 'Unknown Address',
                  'status': transaction['status'] ?? 'Unknown',
                  'date': transaction['tanggal_transaksi'] ?? 'Unknown Date',
                  'items': items,
                });
              }
            }
          }
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
            _deliveryTasks = activeDeliveries;
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

  Future<void> _updateStatus(int index) async {
    final task = _deliveryTasks[index];
    String? newStatus;
    String confirmationMessage;
    String actionText;

    if (task['status'] == 'Siap Dikirim') {
      newStatus = 'Sedang Dikirim';
      confirmationMessage = 'Konfirmasi bahwa pengiriman telah dimulai?';
      actionText = 'Konfirmasi Pengiriman';
    } else if (task['status'] == 'Sedang Dikirim') {
      newStatus = 'Sudah Diterima';
      confirmationMessage = 'Konfirmasi bahwa pengiriman telah diterima?';
      actionText = 'Konfirmasi Diterima';
    } else {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size.width * 0.04)),
          title: Text(
            'Konfirmasi Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A7C52),
              fontSize: size.width * 0.045,
            ),
          ),
          content: Text(
            confirmationMessage,
            style: TextStyle(fontSize: size.width * 0.04),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: size.width * 0.035,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                actionText,
                style: TextStyle(
                  color: Color(0xFF7A7C52),
                  fontSize: size.width * 0.035,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        final response = await http.put(
          Uri.parse(
              'http://192.168.154.254:8000/api/kurir/transaksi-penjualan/${task['id_penjualan']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'STATUS': newStatus}),
        );

        if (response.statusCode == 200) {
          setState(() {
            if (newStatus == 'Sudah Diterima') {
              _deliveryTasks.removeAt(index);
              _dashboardData!['completed_deliveries']++;
            } else {
              _deliveryTasks[index]['status'] = newStatus;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status diubah menjadi $newStatus',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.025),
              ),
            ),
          );
        } else {
          final responseBody = jsonDecode(response.body);
          final errorMessage = responseBody['message'] ??
              'Gagal memperbarui status: ${response.statusCode}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.025),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error memperbarui status: $e',
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.025),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final oliveGreen = const Color(0xFF7A7C52);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white, Colors.grey[50]!],
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(size.width * 0.06),
                    bottomRight: Radius.circular(size.width * 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: size.width * 0.04,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                height: size.height * 0.18,
                child: Stack(
                  children: [
                    Positioned(
                      top: -size.height * 0.06,
                      right: -size.width * 0.12,
                      child: Container(
                        width: size.width * 0.35,
                        height: size.width * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -size.height * 0.04,
                      left: -size.width * 0.08,
                      child: Container(
                        width: size.width * 0.25,
                        height: size.width * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.015,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: size.width * 0.12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Courier Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.05,
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
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.all(size.width * 0.04),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: size.height * 0.12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width < 600 ? 2 : 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: size.width * 0.04,
                mainAxisSpacing: size.width * 0.04,
              ),
              itemCount: 2,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Container(
              height: size.height * 0.25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BounceInDown(
            child: Container(
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: size.width * 0.2,
                color: Colors.red[400],
              ),
            ),
          ),
          SizedBox(height: size.height * 0.03),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: size.width * 0.05,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.all(size.width * 0.04),
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
          SizedBox(height: size.height * 0.03),
          FadeInUp(
            duration: const Duration(milliseconds: 1200),
            child: _buildDeliveryTasksSection(),
          ),
          SizedBox(height: size.height * 0.1),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A7C52), Color(0xFF5A5D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: size.width * 0.02,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_dashboardData!['name']}!',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Manage your delivery tasks here.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: size.width * 0.035,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final size = MediaQuery.of(context).size;
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.width < 600 ? 2 : 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: size.width * 0.04,
        mainAxisSpacing: size.width * 0.04,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  Widget _buildDeliveryTasksSection() {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Tasks',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A7C52),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: size.height * 0.02),
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
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: size.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Belum ada tugas pengiriman',
            style: TextStyle(
              fontSize: size.width * 0.04,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTaskCard(Map<String, dynamic> task, int index) {
    final size = MediaQuery.of(context).size;
    Color getStatusColor() {
      switch (task['status']) {
        case 'Siap Dikirim':
          return Colors.orange;
        case 'Sedang Dikirim':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03)),
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size.width * 0.03),
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: getStatusColor(),
                    size: size.width * 0.06,
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Nota ${task['order_id']}',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3C34),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        task['customer_name'],
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              task['address'],
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: size.height * 0.01),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.02,
                vertical: size.height * 0.005,
              ),
              decoration: BoxDecoration(
                color: getStatusColor(),
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
              child: Text(
                task['status'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.025,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: size.height * 0.015),
            size.width < 360
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourierDeliveryDetailScreen(
                                delivery: task,
                                onStatusUpdated: _fetchDashboardData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF7A7C52),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * 0.02),
                            side: BorderSide(color: Color(0xFF7A7C52)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.01,
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      ElevatedButton(
                        onPressed: task['status'] == 'Sudah Diterima'
                            ? null
                            : () => _updateStatus(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7A7C52),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.01,
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          task['status'] == 'Siap Dikirim'
                              ? 'Konfirmasi Pengiriman'
                              : task['status'] == 'Sedang Dikirim'
                                  ? 'Konfirmasi Diterima'
                                  : 'Selesai',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourierDeliveryDetailScreen(
                                delivery: task,
                                onStatusUpdated: _fetchDashboardData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF7A7C52),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * 0.02),
                            side: BorderSide(color: Color(0xFF7A7C52)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.01,
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: size.width * 0.02),
                      ElevatedButton(
                        onPressed: task['status'] == 'Sudah Diterima'
                            ? null
                            : () => _updateStatus(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7A7C52),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(size.width * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.01,
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          task['status'] == 'Siap Dikirim'
                              ? 'Konfirmasi Pengiriman'
                              : task['status'] == 'Sedang Dikirim'
                                  ? 'Konfirmasi Diterima'
                                  : 'Selesai',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    final size = MediaQuery.of(context).size;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, stat['color'].withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size.width * 0.03),
        ),
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    stat['icon'],
                    color: stat['color'],
                    size: size.width * 0.07,
                  ),
                  SizedBox(width: size.width * 0.02),
                  Flexible(
                    child: Text(
                      stat['title'],
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                stat['value'].toString(),
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
