import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:p3l_mobile/services/auth_service.dart';
import 'catalogue_screen.dart';
import 'riwayat_pesanan.dart';
import 'profile.dart';
import 'package:p3l_mobile/screens/otentikasi/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_detail.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

const String baseUrl = 'http://10.0.2.2:8000/api';

class PembeliScreen extends StatefulWidget {
  const PembeliScreen({super.key});

  @override
  _PembeliScreenState createState() => _PembeliScreenState();
}

class _PembeliScreenState extends State<PembeliScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final AuthService authService = AuthService();
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  final List<Widget> _pages = [
    const HomeTab(),
    const CatalogueScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home_rounded, label: 'Beranda'),
    NavItem(icon: Icons.search_rounded, label: 'Katalog'),
    NavItem(icon: Icons.receipt_long_rounded, label: 'Riwayat Pesanan'),
    NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    if (index == 2 || index == 3) {
      final token = await authService.getToken();
      if (token == null) {
        bool? shouldLogin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Login Diperlukan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF77784A),
              ),
            ),
            content: const Text(
                'Anda harus login untuk mengakses halaman ini. Apakah Anda ingin login sekarang?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Color(0xFF77784A)),
                ),
              ),
            ],
          ),
        );

        if (shouldLogin == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
        return;
      }
    }

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController?.forward().then((_) {
        _animationController?.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Stack(
                children: [
                  PhysicalModel(
                    color: Colors.transparent,
                    elevation: 10,
                    shadowColor: Colors.black.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF7A7C52),
                              const Color(0xFF6A6D42),
                              const Color(0xFF5A5D32),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_navItems.length, (index) {
                            return Expanded(
                              child: _buildNavItem(index),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    left: (_selectedIndex * (size.width / 4)) +
                        (size.width / 8) -
                        25,
                    top: 5,
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final navItem = _navItems[index];

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? 60 : 0,
              height: isSelected ? 60 : 0,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isSelected ? 0.15 : 0),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation:
                      _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isSelected &&
                              (_animationController?.isAnimating == true)
                          ? _scaleAnimation?.value ?? 1.0
                          : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isSelected ? 8 : 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          navItem.icon,
                          color: Colors.white,
                          size: isSelected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 12 : 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1.0 : 0.7,
                    child: Text(navItem.label),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoggedIn = false;
  final AuthService _authService = AuthService();
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _authService.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  Future<void> _fetchCategories() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/categories'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          List<dynamic> categories;

          if (jsonResponse is List) {
            categories = jsonResponse;
          } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
            categories = jsonResponse['data'];
          } else {
            throw Exception('Unexpected response format: ${response.body}');
          }

          if (categories.isNotEmpty &&
              categories
                  .every((cat) => cat is Map && cat.containsKey('NAMA'))) {
            if (mounted) {
              setState(() {
                _categories = categories;
                _isLoadingCategories = false;
                _errorMessage = null;
              });
            }
            return;
          } else {
            throw Exception('Categories missing NAMA field: ${response.body}');
          }
        } else {
          throw Exception(
              'Failed to load categories: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          if (mounted) {
            setState(() {
              _isLoadingCategories = false;
              _errorMessage = e.toString();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat kategori: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'elektronik & gadget':
        return Icons.devices;
      case 'perabotan rumah tangga':
        return Icons.home;
      case 'pakaian & aksesori':
        return Icons.shopping_bag;
      case 'buku, alat tulis, & peralatan sekolah':
        return Icons.book;
      case 'hobi, mainan, & koleksi':
        return Icons.toys;
      case 'perlengkapan bayi & anak':
        return Icons.child_care;
      case 'otomotif & aksesori':
        return Icons.directions_car;
      case 'perlengkapan taman & outdoor':
        return Icons.local_florist;
      case 'peralatan kantor & industri':
        return Icons.print;
      case 'kosmetik & perawatan diri':
        return Icons.spa;
      default:
        return Icons.category;
    }
  }

  Future<void> _fetchProducts() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/products/mobile'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          List<dynamic> products;

          if (jsonResponse['success'] && jsonResponse['data'] is List) {
            products = jsonResponse['data'].map((product) {
              product['image'] = product['image'] != '/api/placeholder/60/60'
                  ? '$baseUrl/products/${product['id']}/thumbnail'
                  : '/api/placeholder/60/60';
              return product;
            }).toList();
            products.shuffle();
            products = products.take(10).toList();
            if (mounted) {
              setState(() {
                _products = products;
                _isLoadingProducts = false;
                _errorMessage = null;
              });
            }
            return;
          } else {
            throw Exception('Unexpected response format: ${response.body}');
          }
        } else {
          throw Exception('Failed to load products: ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          if (mounted) {
            setState(() {
              _isLoadingProducts = false;
              _errorMessage = e.toString();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat produk: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final oliveGreen = const Color(0xFF7A7C52);
    final backgroundColor = Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/hero-bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: oliveGreen.withOpacity(0.7),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Cari Produk....',
                                    prefixIcon:
                                        Icon(Icons.search, color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _isLoggedIn
                                ? Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications,
                                          color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  )
                                : Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.login,
                                          color: Colors.white),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 1000),
                        child: const Text(
                          'Temukan\nKesempatan Baru\ndalam Barang Lama',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _StatItem(
                          label: '200+',
                          description: 'Pembeli Puas',
                        ),
                        _StatItem(
                          label: '100+',
                          description: 'Dipercaya Penitip',
                        ),
                        _StatItem(
                          label: '100%',
                          description: 'Barang Layak Pakai',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Stack(
                    children: [
                      PhysicalModel(
                        color: Colors.transparent,
                        elevation: 10,
                        shadowColor: Colors.black.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: Container(
                            width: double.infinity,
                            color: backgroundColor,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            ProductSection(
                              products: _products,
                              isLoading: _isLoadingProducts,
                              errorMessage: _errorMessage,
                              onRetry: _fetchProducts,
                            ),
                            CategorySection(
                              categories: _categories,
                              getIcon: _getIconForCategory,
                              isLoading: _isLoadingCategories,
                              errorMessage: _errorMessage,
                              onRetry: _fetchCategories,
                            ),
                            const SizedBox(height: 24),
                            FadeInUp(
                              duration: const Duration(milliseconds: 1000),
                              child: Container(
                                color: oliveGreen.withOpacity(0.3),
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Mengapa Memilih ReuseMart',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: oliveGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _InfoCard(
                                          icon: Icons.eco,
                                          label: 'Ramah Lingkungan',
                                        ),
                                        const SizedBox(width: 12),
                                        _InfoCard(
                                          icon: Icons.verified,
                                          label: 'Terpercaya',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoCard(
                                      icon: Icons.savings,
                                      label: 'Hemat Budget',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInUp(
                              duration: const Duration(milliseconds: 1200),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/hero-bg.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  height: 390,
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.black12,
                                          Colors.black54,
                                          Colors.black,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(25),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 140),
                                        const Text(
                                          'Temukan Barang Berkualitas dengan Mudah',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Daftar sekarang sebagai pembeli dan jelajahi ribuan produk preloved yang telah dikurasi. Hemat lebih banyak, temukan lebih cepat.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: oliveGreen,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 24),
                                            ),
                                            onPressed: () {},
                                            child: const Text(
                                              'Lanjutkan Pembelian di Website Kami',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SlideInUp(
                              duration: const Duration(milliseconds: 1000),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
                                color: const Color(0xFF7A7C52),
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ReUseMart',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'ReuseMart adalah platform jual beli barang bekas terpercaya di Yogyakarta, mendukung transaksi mudah dan ramah lingkungan. Gabunglah dengan kami untuk menemukan barang berkualitas dengan harga terjangkau.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '© 2025 ReuseMart. All Rights Reserved.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  final List<dynamic> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const ProductSection({
    super.key,
    required this.products,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  Widget _buildProductLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 160,
            height: 160,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 100,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan Barang Berkualitas dan Mudah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3C34),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: isLoading
                ? _buildProductLoadingShimmer()
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Error: $errorMessage',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: onRetry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A7C52),
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : products.isEmpty
                        ? const Center(child: Text('Tidak ada produk tersedia'))
                        : PageView.builder(
                            itemCount: (products.length / 2).ceil(),
                            itemBuilder: (context, index) {
                              final int firstProductIndex = index * 2;
                              final int secondProductIndex =
                                  firstProductIndex + 1;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ProductCard(
                                      id: products[firstProductIndex]['id'],
                                      title: products[firstProductIndex]
                                          ['name'],
                                      price: products[firstProductIndex]
                                              ['price']
                                          .toString(),
                                      imageUrl: products[firstProductIndex]
                                          ['image'],
                                    ),
                                    if (secondProductIndex < products.length)
                                      ProductCard(
                                        id: products[secondProductIndex]['id'],
                                        title: products[secondProductIndex]
                                            ['name'],
                                        price: products[secondProductIndex]
                                                ['price']
                                            .toString(),
                                        imageUrl: products[secondProductIndex]
                                            ['image'],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Lanjutkan Pembelian di Website Kami',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1A3C34),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String imageUrl;

  const ProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    String formatRupiah(String price) {
      final number = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 'Rp ${NumberFormat("#,##0", "id_ID").format(number)}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 160,
          height: 160,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != '/api/placeholder/60/60'
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.grey,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('Image load error: $error, URL: $url');
                            return Image.asset(
                              'assets/images/placeholder.png',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(price),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3C34),
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
}

class CategorySection extends StatelessWidget {
  final List<dynamic> categories;
  final IconData Function(String) getIcon;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const CategorySection({
    super.key,
    required this.categories,
    required this.getIcon,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  List<List<Map<String, dynamic>>> _groupCategories() {
    List<List<Map<String, dynamic>>> grouped = [];
    for (int i = 0; i < categories.length; i += 2) {
      grouped.add(
        categories
            .sublist(i, i + 2 > categories.length ? categories.length : i + 2)
            .map((cat) => {
                  'name': cat['NAMA'],
                  'icon': getIcon(cat['NAMA']),
                })
            .toList(),
      );
    }
    return grouped;
  }

  Widget _buildCategoryLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(2, (i) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 180,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedCategories = _groupCategories();
    const double cardWidth = 180.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Barang Bekas ReuseMart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3C34),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: isLoading
                ? _buildCategoryLoadingShimmer()
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Error: $errorMessage',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: onRetry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A7C52),
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : groupedCategories.isEmpty
                        ? const Center(
                            child: Text('Tidak ada kategori tersedia'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: groupedCategories.length,
                            itemBuilder: (context, index) {
                              final pair = groupedCategories[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: pair.map((category) {
                                    return SizedBox(
                                      width: cardWidth,
                                      height: 60,
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                category['icon'],
                                                size: 24,
                                                color: const Color(0xFF1A3C34),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  category['name'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String description;

  const _StatItem({
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  static const oliveGreen = Color(0xFF7A7C52);

  const _InfoCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            oliveGreen,
            Color(0xFF5A5D32),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
