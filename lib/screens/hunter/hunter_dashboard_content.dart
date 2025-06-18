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
  List<dynamic> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  final List<String> _statusFilters = [
    'All',
    'Tersedia',
    'Terjual',
    'Didonasikan',
    'Dikembalikan',
    'Kadaluarsa',
    'Siap Diambil Kembali',
    'Hangus'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // In _DashboardContentState class

  Future<void> _fetchDashboardData({String? search, String? status}) async {
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

        final commissionResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/hunter/komisi'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        // Build query parameters for consigned items
        final queryParams = <String, String>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        if (status != null && status != 'All') {
          queryParams['status'] = status;
        }

        final itemsResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/hunter/barang-titipan')
              .replace(queryParameters: queryParams),
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
          totalItemsHunted = hauntedItems.length;
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
            _filteredItems = hauntedItems;
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

  void _filterItems() {
    final query = _searchController.text;
    final status = _selectedStatus;
    // Trigger API call with search and status
    _fetchDashboardData(search: query, status: status);
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
                                    'Hunter Dashboard',
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
            child: _buildSearchAndFilter(),
          ),
          SizedBox(height: size.height * 0.02),
          FadeInUp(
            duration: const Duration(milliseconds: 1400),
            child: _buildHauntedItemsSection(),
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
            'Manage your consigned items here.',
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

  Widget _buildSearchAndFilter() {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size.width * 0.02),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: size.width * 0.02,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product, penitip, or code...',
                prefixIcon: Icon(Icons.search, size: size.width * 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: size.height * 0.015,
                  horizontal: size.width * 0.04,
                ),
              ),
              style: TextStyle(fontSize: size.width * 0.035),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.width * 0.02),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: size.width * 0.02,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _selectedStatus,
            items: _statusFilters.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: size.width * 0.035),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
                _filterItems();
              });
            },
            underline: const SizedBox(),
            icon: Icon(Icons.filter_list, size: size.width * 0.05),
            borderRadius: BorderRadius.circular(size.width * 0.02),
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.01,
              horizontal: size.width * 0.02,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHauntedItemsSection() {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consigned Items',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7A7C52),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: size.height * 0.02),
        _filteredItems.isEmpty
            ? _buildEmptyHauntedItems()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
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
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: size.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Belum ada barang titipan',
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

  Widget _buildHauntedItemCard(Map<String, dynamic> item) {
    final size = MediaQuery.of(context).size;
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.width * 0.03),
      ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                  child: CachedNetworkImage(
                    imageUrl: item['product_image'],
                    width: size.width * 0.15,
                    height: size.width * 0.15,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: size.width * 0.15,
                        height: size.width * 0.15,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('Image Load Error for $url: $error');
                      return Container(
                        width: size.width * 0.15,
                        height: size.width * 0.15,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'],
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A3C34),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        item['penitip_name'],
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
              'Kode: ${item['KODE_PRODUK']}',
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey,
              ),
              maxLines: 1,
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
                item['status'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.025,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: size.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommissionDetailScreen(
                          commission: Commission(
                            commissionId: item['KODE_PRODUK'],
                            productName: item['product_name'],
                            penitipName: item['penitip_name'],
                            amount: 0,
                            date: item['consignment_date'],
                            status: item['status'],
                            imagePath: item['product_image'],
                            transactionDate: item['transaction_date'] ??
                                item['consignment_date'],
                            consignmentDate: item['consignment_date'],
                            sellingPrice: item['selling_price'] ?? 0,
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7A7C52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                      side: const BorderSide(color: Color(0xFF7A7C52)),
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
        borderRadius: BorderRadius.circular(size.width * 0.03),
      ),
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
