import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'penukaran_history.dart';

class MerchandiseListScreen extends StatefulWidget {
  const MerchandiseListScreen({super.key});

  @override
  State<MerchandiseListScreen> createState() => _MerchandiseListScreenState();
}

class _MerchandiseListScreenState extends State<MerchandiseListScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  int? userPoints;
  List<dynamic> merchandise = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listAnimationController.forward();
    });

    _fetchUserPoints();
    _fetchMerchandise();
  }

  Future<void> _fetchUserPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        setState(() {
          userPoints = profileData['user']['poin'];
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat poin pengguna.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMerchandise() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/merchandise'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          merchandise = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat merchandise.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
              Colors.grey[100]!,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 140,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: AnimatedBuilder(
                animation: _headerFadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_headerSlideAnimation.value, 0),
                    child: Opacity(
                      opacity: _headerFadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF77784A),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xFF77784A),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PenukaranHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF77784A),
                        const Color(0xFF8B8C5E),
                        const Color(0xFF5A5D3A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF77784A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: AnimatedBuilder(
                      animation: _headerFadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _headerSlideAnimation.value * 0.5),
                          child: Opacity(
                            opacity: _headerFadeAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.redeem_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Tukar Poin',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.stars_rounded,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Poin Anda: ${userPoints ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tukarkan poin dengan merchandise eksklusif',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = merchandise[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: Duration(milliseconds: 100 + (index * 100)),
                      child: PointsMerchandiseCard(
                        merchandiseId: item['ID_MERCHANDISE'],
                        productName: item['NAMA'],
                        pointsRequired: item['POIN_DIBUTUHKAN'],
                        stock: item['STOK'],
                        imageUrl: item['URL_GAMBAR'],
                        userPoints: userPoints ?? 0,
                        isPopular: index == 0 || index == 3,
                        onExchangeSuccess: () {
                          _fetchUserPoints();
                          _fetchMerchandise();
                        },
                      ),
                    );
                  },
                  childCount: merchandise.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PointsMerchandiseCard extends StatelessWidget {
  final int merchandiseId;
  final String productName;
  final int pointsRequired;
  final int stock;
  final String? imageUrl;
  final int userPoints;
  final bool isPopular;
  final VoidCallback onExchangeSuccess;

  const PointsMerchandiseCard({
    super.key,
    required this.merchandiseId,
    required this.productName,
    required this.pointsRequired,
    required this.stock,
    required this.imageUrl,
    required this.userPoints,
    this.isPopular = false,
    required this.onExchangeSuccess,
  });

  bool get canAfford => userPoints >= pointsRequired;
  bool get inStock => stock > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? const Color(0xFF77784A).withOpacity(0.3)
              : const Color(0xFF77784A).withOpacity(0.1),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          if (isPopular)
            BoxShadow(
              color: const Color(0xFF77784A).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAfford && inStock
              ? () {
                  _showExchangeDialog(context, merchandiseId);
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[100]!,
                            Colors.grey[50]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF77784A).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF77784A),
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFF77784A),
                                      size: 40,
                                    ),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: const Alignment(-1.0, -0.3),
                                  end: const Alignment(1.0, 0.3),
                                ),
                              ),
                            ),
                          ),
                          if (!canAfford || !inStock)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                child: Center(
                                  child: Text(
                                    !inStock ? 'HABIS' : 'POIN\nTIDAK CUKUP',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3C34),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: inStock ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stok: $stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: inStock
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: canAfford
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF77784A),
                                        Color(0xFF8B8C5E)
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey[400]!,
                                        Colors.grey[500]!
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$pointsRequired Poin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
              if (isPopular)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'POPULER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExchangeDialog(BuildContext context, int merchandiseId) {
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Konfirmasi Penukaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C34),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apakah Anda yakin ingin menukar:'),
                  const SizedBox(height: 8),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF77784A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Dengan $pointsRequired poin?'),
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF77784A),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() {
                            isProcessing = true;
                          });

                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('token');
                          if (token == null) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan login kembali.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final response = await http.post(
                              Uri.parse('http://10.0.2.2:8000/api/penukaran'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body:
                                  jsonEncode({'ID_MERCHANDISE': merchandiseId}),
                            );

                            Navigator.of(context).pop();
                            if (response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Penukaran berhasil!'),
                                  backgroundColor: Color(0xFF77784A),
                                ),
                              );
                              onExchangeSuccess();
                            } else {
                              final errorData = jsonDecode(response.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    errorData['message'] ?? 'Penukaran gagal.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Terjadi kesalahan: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF77784A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Tukar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
