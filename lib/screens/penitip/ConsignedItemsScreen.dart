import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ConsignedItemDetailScreen.dart'; // Adjust import based on your project structure

const String baseUrl = 'http://10.0.2.2:8000/api';

class ConsignedItemsScreen extends StatefulWidget {
  const ConsignedItemsScreen({super.key});

  @override
  _ConsignedItemsScreenState createState() => _ConsignedItemsScreenState();
}

class _ConsignedItemsScreenState extends State<ConsignedItemsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String? _selectedStatus;
  String _sortBy = 'tanggal_penitipan'; // Default sort by consignment date
  String _sortOrder = 'desc'; // Default: newest (descending)
  List<dynamic> _consignedItems = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));

    _animationController!.forward();

    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMore &&
          _currentPage < _totalPages) {
        _fetchMoreItems();
      }
    });

    _fetchConsignedItems();
  }

  Future<bool> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Connectivity Check Error: $e');
      return false;
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchConsignedItems({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    if (!await _checkConnectivity()) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada koneksi internet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        String? token = await _getAuthToken();
        if (token == null) {
          setState(() {
            _isLoading = false;
            _isFetchingMore = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No token found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          // Optionally navigate to login screen
          // Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        final response = await http.get(
          Uri.parse(
              '$baseUrl/penitip/barang-titipan?page=$_currentPage&per_page=10'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] && jsonResponse['data'] is List) {
            setState(() {
              var items = jsonResponse['data'].map((item) {
                item['foto_produk'] =
                    item['foto_produk'] != '/api/placeholder/60/60'
                        ? '$baseUrl/products/${item['kode_produk']}/thumbnail'
                        : '/api/placeholder/60/60';
                return {
                  ...item,
                  'images': [item['foto_produk']],
                };
              }).toList();
              if (!isLoadMore) {
                _consignedItems = items;
              } else {
                _consignedItems.addAll(items);
              }
              _totalPages = jsonResponse['meta']['last_page'] ?? 1;
              _isLoading = false;
              _isFetchingMore = false;
              if (isLoadMore) _currentPage++;
            });
            print(
                'Fetched ${_consignedItems.length} consigned items (page $_currentPage)');
            return;
          } else {
            throw Exception('Unexpected response format: ${response.body}');
          }
        } else if (response.statusCode == 401) {
          setState(() {
            _isLoading = false;
            _isFetchingMore = false;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          // Optionally navigate to login screen
          // Navigator.pushReplacementNamed(context, '/login');
          return;
        } else {
          throw Exception(
              'Failed to load consigned items: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print(
            'Fetch Consigned Items Error (Attempt ${attempt + 1}/$maxRetries): $e');
        attempt++;
        if (attempt >= maxRetries) {
          setState(() {
            _isLoading = false;
            _isFetchingMore = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal memuat barang titikan: ${e.toString()}')),
          );
          return;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  Future<void> _fetchMoreItems() async {
    _currentPage++;
    await _fetchConsignedItems(isLoadMore: true);
  }

  List<dynamic> get _filteredItems {
    List<dynamic> filteredItems = List.from(_consignedItems);
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        String status = item['status'] ?? '';
        // Map "Telah Didonasikan" to "Didonasikan" for filtering
        if (_selectedStatus == 'Telah Didonasikan') {
          return status == 'Didonasikan';
        }
        return status == _selectedStatus;
      }).toList();
    }
    if (_sortBy == 'tanggal_penitipan') {
      filteredItems.sort((a, b) {
        DateTime dateA = DateTime.parse(a['tanggal_penitipan']);
        DateTime dateB = DateTime.parse(b['tanggal_penitipan']);
        return _sortOrder == 'desc'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      });
    } else if (_sortBy == 'tanggal_kadaluarsa') {
      filteredItems.sort((a, b) {
        DateTime dateA = a['tanggal_kadaluarsa'] != '-'
            ? DateTime.parse(a['tanggal_kadaluarsa'])
            : DateTime(1970, 1, 1);
        DateTime dateB = b['tanggal_kadaluarsa'] != '-'
            ? DateTime.parse(b['tanggal_kadaluarsa'])
            : DateTime(1970, 1, 1);
        return _sortOrder == 'asc'
            ? dateA.compareTo(dateB)
            : dateB.compareTo(dateA);
      });
    }
    return filteredItems;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const oliveGreen = Color(0xFF7A7C52);
    const double bottomNavBarHeight =
        56.0; // Standard BottomNavigationBar height

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 8,
                backgroundColor: Colors.transparent,
                flexibleSpace: AnimatedBuilder(
                  animation: _animationController!,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
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
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FadeInDown(
                                                  duration: const Duration(
                                                      milliseconds: 800),
                                                  child: LayoutBuilder(
                                                    builder:
                                                        (context, constraints) {
                                                      double availableWidth =
                                                          constraints.maxWidth;
                                                      String displayText =
                                                          _getDisplayText(
                                                              availableWidth,
                                                              _isScrolled);
                                                      double fontSize =
                                                          _getFontSize(
                                                              _isScrolled,
                                                              availableWidth);

                                                      return Text(
                                                        displayText,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: fontSize,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          height: 1.2,
                                                        ),
                                                        maxLines:
                                                            _isScrolled ? 1 : 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        softWrap: true,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                if (!_isScrolled) ...[
                                                  const SizedBox(height: 6),
                                                  FadeInDown(
                                                    duration: const Duration(
                                                        milliseconds: 900),
                                                    child: const Text(
                                                      'Lihat barang yang Anda titipkan',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                        height: 1.3,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!_isScrolled) ...[
                                        const SizedBox(height: 16),
                                        FadeInUp(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.95),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Colors.grey,
                                                    size: 22,
                                                  ),
                                                ),
                                                const Expanded(
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Cari barang Anda...',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                expandedHeight: _isScrolled ? 90 : 180,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 5.0, 16.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3C34),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Barang Titipan Saya',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3C34),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredItems.length} barang',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isLoading
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.65, // Adjusted to accommodate extra text
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 100,
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 16,
                                                width: 100,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              SizedBox(
                                                height: 12,
                                                width: 80,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              SizedBox(
                                                height: 12,
                                                width: 60,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
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
                              },
                            )
                          : _filteredItems.isEmpty
                              ? const Center(
                                  child: Text('Tidak ada barang tersedia'))
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        0.65, // Adjusted to accommodate extra text
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _filteredItems.length +
                                      (_isFetchingMore ? 2 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= _filteredItems.length) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 100,
                                                width: double.infinity,
                                                decoration: const BoxDecoration(
                                                  color: Colors.grey,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                          top: Radius.circular(
                                                              12)),
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 16,
                                                      width: 100,
                                                      child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          4)),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    SizedBox(
                                                      height: 12,
                                                      width: 80,
                                                      child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          4)),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    SizedBox(
                                                      height: 12,
                                                      width: 60,
                                                      child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          4)),
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
                                    final item = _filteredItems[index];
                                    return FadeInUp(
                                      duration: Duration(
                                          milliseconds: 500 + (index * 100)),
                                      child: ConsignedItemCard(
                                        id: item['kode_produk'].toString(),
                                        title:
                                            item['nama'] ?? 'Barang Tanpa Nama',
                                        price: _formatRupiah(
                                            item['harga_jual'] ?? 0),
                                        status: item['status'] ?? 'N/A',
                                        images: List<String>.from(
                                            item['images'] ??
                                                ['/api/placeholder/60/60']),
                                        condition: item['kondisi'] ?? 'N/A',
                                        weight:
                                            item['berat']?.toString() ?? 'N/A',
                                        warranty:
                                            item['tanggal_garansi'] ?? '-',
                                        description: item['deskripsi'] ?? '',
                                        tanggalPenitipan:
                                            item['tanggal_penitipan'] ?? '-',
                                        tanggalKadaluarsa:
                                            item['tanggal_kadaluarsa'] ?? '-',
                                      ),
                                    );
                                  },
                                ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 100, // Above bottom navigation bar with 16px margin
            right: 16,
            child: ZoomIn(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3C34).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _showFilterSortDialog(context);
                  },
                  backgroundColor: const Color(0xFF1A3C34),
                  elevation: 0,
                  label: const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(num price) {
    return 'Rp ${NumberFormat("#,##0", "id_ID").format(price)}';
  }

  String _getDisplayText(double availableWidth, bool isScrolled) {
    if (isScrolled) {
      return availableWidth < 250 ? 'Barang Saya' : 'Barang Titipan';
    } else {
      if (availableWidth < 280) {
        return 'Barang Titipan\nSaya';
      } else {
        return 'Barang Titipan Saya';
      }
    }
  }

  double _getFontSize(bool isScrolled, double availableWidth) {
    if (isScrolled) {
      return availableWidth < 250 ? 14 : 16;
    } else {
      if (availableWidth < 280) {
        return 18;
      } else {
        return 20;
      }
    }
  }

  void _showFilterSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C34),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Tanggal Penitipan: Terbaru'),
                onTap: () {
                  setState(() {
                    _sortBy = 'tanggal_penitipan';
                    _sortOrder = 'desc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Tanggal Penitipan: Terlama'),
                onTap: () {
                  setState(() {
                    _sortBy = 'tanggal_penitipan';
                    _sortOrder = 'asc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Tanggal Kadaluarsa: Terdekat'),
                onTap: () {
                  setState(() {
                    _sortBy = 'tanggal_kadaluarsa';
                    _sortOrder = 'asc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Tanggal Kadaluarsa: Terjauh'),
                onTap: () {
                  setState(() {
                    _sortBy = 'tanggal_kadaluarsa';
                    _sortOrder = 'desc';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_alt, color: Color(0xFF1A3C34)),
                title: const Text('Filter by Status'),
                onTap: () {
                  Navigator.pop(context);
                  _showStatusFilterDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C34),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tersedia'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Tersedia';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Terjual'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Terjual';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Hangus'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Hangus';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Kadaluarsa'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Kadaluarsa';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Telah Didonasikan'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Telah Didonasikan';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Siap Diambil Kembali'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Siap Diambil Kembali';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Dikembalikan'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'Dikembalikan';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear, color: Color(0xFF1A3C34)),
                  title: const Text('Clear Filter'),
                  onTap: () {
                    setState(() {
                      _selectedStatus = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConsignedItemCard extends StatefulWidget {
  final String id;
  final String title;
  final String price;
  final String status;
  final List<String> images;
  final String condition;
  final String weight;
  final String warranty;
  final String description;
  final String tanggalPenitipan;
  final String tanggalKadaluarsa;

  const ConsignedItemCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.status,
    required this.images,
    required this.condition,
    required this.weight,
    required this.warranty,
    required this.description,
    required this.tanggalPenitipan,
    required this.tanggalKadaluarsa,
  });

  @override
  _ConsignedItemCardState createState() => _ConsignedItemCardState();
}

class _ConsignedItemCardState extends State<ConsignedItemCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsignedItemDetailScreen(
          id: widget.id,
          title: widget.title,
          price: widget.price,
          status: widget.status,
          images: widget.images,
          description: widget.description,
          condition: widget.condition,
          weight: widget.weight,
          tanggalPenitipan: widget.tanggalPenitipan,
          tanggalKadaluarsa: widget.tanggalKadaluarsa,
          rating: null, // Rating fetched from API
        ),
      ),
    );
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  Color getStatusColor() {
    switch (widget.status) {
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

  String _formatDate(String dateString) {
    if (dateString == '-') {
      return 'N/A';
    }
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      print('Error formatting date $dateString: $e');
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.images.isNotEmpty && widget.images[0].isNotEmpty
        ? widget.images[0]
        : '/api/placeholder/60/60';
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'consignedItemImage${widget.id}_0',
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) {
                      print('Image Load Error for $url: $error');
                      return Image.asset(
                        'assets/images/placeholder.png',
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.status,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Penitipan: ${_formatDate(widget.tanggalPenitipan)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kadaluarsa: ${_formatDate(widget.tanggalKadaluarsa)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
}
