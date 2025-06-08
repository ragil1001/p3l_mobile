import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import 'hunter_commission_detail.dart';
import '../../models/comission.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  List<dynamic> _hauntedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _authService.getToken();
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
            !profileData['user']['role'].contains('hunter')) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Akses hanya untuk Hunter.';
              _isLoading = false;
            });
          }
          return;
        }

        final hunterId = await _authService.getUserId();

        // Fetch commissions for stats
        final commissionResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/hunter/komisi'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        // Fetch consigned items for Haunted Items
        final itemsResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/hunter/barang-titipan'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        int totalCommission = 0;
        int totalItemsHunted = 0;
        List<dynamic> hauntedItems = [];

        if (commissionResponse.statusCode == 200) {
          final commissions = jsonDecode(commissionResponse.body) as List;
          totalCommission = commissions.fold(
              0, (sum, item) => sum + ((item['KOMISI_HUNTER'] ?? 0) as int));
        } else {
          final errorData = jsonDecode(commissionResponse.body);
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Gagal memuat komisi: ${errorData['message'] ?? commissionResponse.statusCode}';
              _isLoading = false;
            });
          }
          return;
        }

        if (itemsResponse.statusCode == 200) {
          final items = jsonDecode(itemsResponse.body)['data'] as List;
          hauntedItems = items.map((item) {
            return {
              'KODE_PRODUK': item['KODE_PRODUK'] ?? 'Unknown ID',
              'product_name': item['product_name'] ?? 'Unknown Product',
              'penitip_name': item['penitip_name'] ?? 'Unknown Penitip',
              'consignment_date': item['consignment_date'] ?? 'Unknown Date',
              'status': item['status'] ?? 'Pending',
              'product_image': item['product_image'] != null &&
                      item['product_image'] != '/api/placeholder/60/60'
                  ? 'http://10.0.2.2:8000/api/products/${item['KODE_PRODUK']}/thumbnail'
                  : 'http://10.0.2.2:8000/api/placeholder/60/60',
            };
          }).toList();
          totalItemsHunted = hauntedItems.length; // Count total consigned items
        } else {
          final errorData = jsonDecode(itemsResponse.body);
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Gagal memuat barang titipan: ${errorData['message'] ?? itemsResponse.statusCode}';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _dashboardData = {
              'total_items_hunted': totalItemsHunted,
              'total_commission': totalCommission,
              'name': profileData['user']['nama'],
            };
            _hauntedItems = hauntedItems;
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
        final errorData = jsonDecode(profileResponse.body);
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat profil: ${errorData['message'] ?? profileResponse.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: Koneksi gagal. Silakan coba lagi.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
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
                                    'Hunter Dashboard',
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
            child: _buildHauntedItemsSection(),
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
            'Track your hunting items and commissions here.',
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
        'title': 'Items Hunted',
        'value': _dashboardData!['total_items_hunted'],
        'icon': Icons.inventory_2,
        'color': Colors.blue,
      },
      {
        'title': 'Total Commission',
        'value':
            'Rp ${NumberFormat("#,##0", "id_ID").format(_dashboardData!['total_commission'])}',
        'icon': Icons.monetization_on,
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

  Widget _buildHauntedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Haunted Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A7C52),
          ),
        ),
        const SizedBox(height: 16),
        _hauntedItems.isEmpty
            ? _buildEmptyHauntedItems()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _hauntedItems.length,
                itemBuilder: (context, index) {
                  final item = _hauntedItems[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 600 + (index * 200)),
                    child: _buildHauntedItemCard(item),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyHauntedItems() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada barang yang dihunting',
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

  Widget _buildHauntedItemCard(Map<String, dynamic> item) {
    Color getStatusColor() {
      switch (item['status']) {
        case 'Tersedia':
          return Colors.green;
        case 'Terjual':
          return Colors.blue;
        case 'Didonasikan':
          return Colors.orange;
        case 'Dikembalikan':
          return Colors.red;
        case 'Kadaluarsa':
          return Colors.grey;
        case 'Siap Diambil Kembali':
          return Colors.purple;
        case 'Hangus':
          return Colors.black54;
        default:
          return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommissionDetailScreen(
              commission: Commission(
                commissionId: item['KODE_PRODUK'],
                productName: item['product_name'],
                penitipName: item['penitip_name'],
                amount: 0, // No commission data for consigned items
                date: item['consignment_date'],
                status: item['status'],
                imagePath: item['product_image'],
              ),
            ),
          ),
        );
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item['product_image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('Image Load Error for $url: $error');
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C34),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['penitip_name'],
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
                        item['status'],
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
