import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:p3l_mobile/services/auth_service.dart';
import 'package:p3l_mobile/screens/otentikasi/login.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

const String baseUrl = 'http://10.0.2.2:8000/api';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = true;
  bool _isLoadingDiscussions = true;
  Map<String, dynamic>? _product;
  List<dynamic> _discussions = [];
  List<dynamic> _otherProducts = [];
  String? _errorMessage;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _userId;
  List<bool> _imageLoaded = []; // Track loading state of each image

  String _formatRupiah(num price) {
    return 'Rp ${NumberFormat("#,##0", "id_ID").format(price)}';
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchProductDetails();
    _fetchDiscussions();
    _fetchOtherProducts();
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _checkLoginStatus() async {
    if (!await _checkConnectivity()) {
      setState(() {
        _isLoggedIn = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    final token = await _authService.getToken();
    Map<String, dynamic>? user;
    try {
      if (token != null) {
        final response = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          user = jsonResponse['data'];
        }
      }
    } catch (e) {
      user = null;
    }
    setState(() {
      _isLoggedIn = token != null;
      _userId = user?['id']?.toString();
    });
  }

  Future<void> _fetchProductDetails() async {
    if (!await _checkConnectivity()) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tidak ada koneksi internet';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/mobile/${widget.productId}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] && jsonResponse['data'] is Map) {
          var productData = jsonResponse['data'];
          if (productData['photos'] != null &&
              productData['photos'].isNotEmpty) {
            productData['photos'] = productData['photos'].map((photo) {
              photo['url'] = photo['id'] != null
                  ? '$baseUrl/photos/${photo['id']}/optimized'
                  : '/api/placeholder/60/60';
              return photo;
            }).toList();
            setState(() {
              _imageLoaded =
                  List<bool>.filled(productData['photos'].length, false);
            });
          } else {
            productData['photos'] = [
              {'url': '/api/placeholder/60/60', 'is_utama': true}
            ];
            setState(() {
              _imageLoaded = [true]; // Placeholder is considered loaded
            });
          }
          setState(() {
            _product = productData;
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchDiscussions() async {
    if (!await _checkConnectivity()) {
      setState(() {
        _isLoadingDiscussions = false;
        _errorMessage = 'Tidak ada koneksi internet';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diskusi?kode_produk=${widget.productId}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _discussions = (jsonResponse as List).map((discussion) {
            return {
              'NAMA_PELANGGAN':
                  discussion['pembeli']?['NAMA'] ?? 'Pengguna Tidak Dikenal',
              'PESAN_DISKUSI': discussion['PESAN'] ?? 'Pesan tidak tersedia',
              'TANGGAL_DISKUSI': discussion['TANGGAL_DIBUAT'],
              'STATUS_BALASAN': (discussion['balasan'] != null &&
                      discussion['balasan'].isNotEmpty)
                  ? 'Sudah Dibalas'
                  : 'Belum Dibalas',
              'BALASAN': (discussion['balasan'] != null &&
                      discussion['balasan'].isNotEmpty)
                  ? discussion['balasan'][0]['PESAN']
                  : null,
              'TANGGAL_BALASAN': (discussion['balasan'] != null &&
                      discussion['balasan'].isNotEmpty)
                  ? discussion['balasan'][0]['TANGGAL_DIBUAT']
                  : null,
              'NAMA_CS': (discussion['balasan'] != null &&
                      discussion['balasan'].isNotEmpty)
                  ? (discussion['balasan'][0]['pegawai'] != null &&
                          discussion['balasan'][0]['pegawai']['NAMA'] != null
                      ? discussion['balasan'][0]['pegawai']['NAMA']
                      : 'CS Tidak Dikenal')
                  : null,
            };
          }).toList();
          _isLoadingDiscussions = false;
          _errorMessage = null;
        });
      } else {
        throw Exception('Failed to load discussions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingDiscussions = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat diskusi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchOtherProducts() async {
    if (!await _checkConnectivity()) {
      setState(() {
        _otherProducts = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products?exclude=${widget.productId}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] && jsonResponse['data'] is List) {
          setState(() {
            _otherProducts = jsonResponse['data'].take(5).map((product) {
              product['image'] = product['image'] != '/api/placeholder/60/60'
                  ? '$baseUrl/products/${product['id']}/thumbnail'
                  : '/api/placeholder/60/60';
              return product;
            }).toList();
          });
        }
      }
    } catch (e) {
      setState(() {
        _otherProducts = [];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading ? _buildShimmer() : _buildContent(),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ZoomIn(
                    duration: const Duration(milliseconds: 800),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Mengarahkan ke pembelian web'),
                            backgroundColor: const Color(0xFF7A7C52),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A7C52),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag),
                          SizedBox(width: 8),
                          Text('Lanjutkan Pembelian melalui Website'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildShimmer() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.grey,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 100,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                  _imageLoaded = [];
                });
                _fetchProductDetails();
                _fetchDiscussions();
                _fetchOtherProducts();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final images =
        _product!['photos']?.map((photo) => photo['url'] as String).toList() ??
            ['/api/placeholder/60/60'];
    final warranty = _product!['warranty_date'] != null
        ? DateTime.parse(_product!['warranty_date']).toString().split(' ')[0]
        : 'Tidak Ada';
    final penitipName = _product!['penitip_name'] ?? 'Penitip Tidak Dikenal';
    final penitipRating = _product!['penitip_rating']?.toDouble() ?? 0.0;
    final penitipBadge = _product!['penitip_badge'] ?? 0;
    final penitipSalesCount = _product!['penitip_sales_count'] ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (images[index] == '/api/placeholder/60/60') {
                      return Hero(
                        tag: 'productImage${_product!['id']}_$index',
                        child: Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Hero(
                      tag: 'productImage${_product!['id']}_$index',
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.grey,
                          ),
                        ),
                        imageBuilder: (context, imageProvider) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_imageLoaded[index]) {
                              setState(() {
                                _imageLoaded[index] = true;
                                print('Image loaded: ${images[index]}');
                              });
                            }
                          });
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          print('Image load error: $error, URL: $url');
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_imageLoaded[index]) {
                              setState(() {
                                _imageLoaded[index] =
                                    true; // Prevent infinite shimmer
                              });
                            }
                          });
                          return Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF7A7C52).withOpacity(0.7),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _formatRupiah(_product!['price'] ?? 0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A7C52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      _product!['name'].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spesifikasi Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ModernDetailChip(
                                  icon: Icons.verified,
                                  label: 'Kondisi',
                                  value: _product!['condition'],
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ModernDetailChip(
                                  icon: Icons.scale,
                                  label: 'Berat',
                                  value: '${_product!['weight']} kg',
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ModernDetailChip(
                            icon: Icons.security,
                            label: 'Garansi',
                            value: warranty,
                            color: Colors.orange,
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                color: Color(0xFF7A7C52),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informasi Penitip',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      penitipName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (penitipBadge == 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFB700)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'Top Seller',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$penitipSalesCount Barang Terjual',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.yellow[700],
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                penitipRating > 0
                                    ? penitipRating.toStringAsFixed(1)
                                    : 'Belum ada rating',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: Color(0xFF7A7C52),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Deskripsi Produk',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _product!['description'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.forum,
                                color: Color(0xFF7A7C52),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Diskusi Produk',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingDiscussions
                              ? const Center(child: CircularProgressIndicator())
                              : _discussions.isEmpty
                                  ? const Text(
                                      'Belum ada diskusi untuk produk ini.')
                                  : Column(
                                      children: _discussions.map((discussion) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    discussion[
                                                            'NAMA_PELANGGAN'] ??
                                                        'Pengguna Tidak Dikenal',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    discussion['TANGGAL_DISKUSI'] !=
                                                            null
                                                        ? discussion[
                                                                'TANGGAL_DISKUSI']
                                                            .split(' ')[0]
                                                        : 'Tanggal Tidak Tersedia',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  discussion['PESAN_DISKUSI'] ??
                                                      'Pesan tidak tersedia'),
                                              if (discussion[
                                                          'STATUS_BALASAN'] ==
                                                      'Sudah Dibalas' &&
                                                  discussion['BALASAN'] !=
                                                      null) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            discussion[
                                                                    'NAMA_CS'] ??
                                                                'CS Tidak Dikenal',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            discussion['TANGGAL_BALASAN'] !=
                                                                    null
                                                                ? discussion[
                                                                        'TANGGAL_BALASAN']
                                                                    .split(
                                                                        ' ')[0]
                                                                : 'Tanggal Tidak Tersedia',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(discussion[
                                                              'BALASAN'] ??
                                                          'Balasan tidak tersedia'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const Divider(),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1100),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF7A7C52),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Produk Lainnya',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _otherProducts.isEmpty
                        ? const Center(
                            child: Text('Tidak ada produk lain tersedia'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _otherProducts.length,
                            itemBuilder: (context, index) {
                              return FadeInRight(
                                delay: Duration(milliseconds: index * 100),
                                child:
                                    _ModernProductCard(_otherProducts[index]),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _ModernDetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ModernProductCard(this.product);

  String _formatRupiah(num price) {
    return 'Rp ${NumberFormat("#,##0", "id_ID").format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image'] ?? '/api/placeholder/60/60';
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailScreen(productId: product['id'].toString()),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 110,
                width: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  print('Image load error: $error, URL: $url');
                  return Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Produk Tanpa Nama',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(product['price'] ?? 0),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A7C52),
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
