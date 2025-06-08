import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../otentikasi/login.dart';
import '../../screens/homepage.dart';
import 'hunter_commission_history.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _bounceController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _bounceAnimation;

  Map<String, dynamic>? userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchUserProfile();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController!, curve: Curves.easeOut));
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController!, curve: Curves.elasticOut),
    );

    _fadeController!.forward();
    _slideController!.forward();
    _bounceController!.forward();
  }

  Future<void> _fetchUserProfile() async {
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

      final profileResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (profileData['user_type'] == 'pegawai' &&
            profileData['user']['role'].contains('hunter')) {
          final commissionResponse = await http.get(
            Uri.parse('http://10.0.2.2:8000/api/hunter/komisi'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          int totalCommission = 0;
          int totalItemsHunted = 0;
          if (commissionResponse.statusCode == 200) {
            final commissions = jsonDecode(commissionResponse.body);
            totalCommission = commissions.fold(
                0, (sum, item) => sum + (item['KOMISI_HUNTER'] ?? 0));
            totalItemsHunted =
                commissions.map((item) => item['KODE_PRODUK']).toSet().length;
          } else {
            if (mounted) {
              setState(() {
                _errorMessage =
                    'Gagal memuat komisi: ${commissionResponse.statusCode}';
                _isLoading = false;
              });
            }
            return;
          }

          if (mounted) {
            setState(() {
              userProfile = {
                'nama': profileData['user']['nama'],
                'email': profileData['user']['email'],
                'telepon': profileData['user']['telepon'] ?? 'Tidak tersedia',
                'alamat': profileData['user']['alamat'] ?? 'Tidak tersedia',
                'total_commission': totalCommission,
                'total_items_hunted': totalItemsHunted,
                'role': 'Hunter',
              };
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Profil hanya tersedia untuk hunter';
              _isLoading = false;
            });
          }
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
          _errorMessage = 'Error mengambil profil: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _bounceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const oliveGreen = Color(0xFF77784A);

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                oliveGreen,
                oliveGreen.withOpacity(0.8),
                Colors.grey[50]!,
              ],
              stops: const [0.0, 0.4, 0.7],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                oliveGreen,
                oliveGreen.withOpacity(0.8),
                Colors.grey[50]!,
              ],
              stops: const [0.0, 0.4, 0.7],
            ),
          ),
          child: Center(child: Text(_errorMessage!)),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              oliveGreen,
              oliveGreen.withOpacity(0.8),
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.4, 0.7],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _fadeAnimation != null
                    ? FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _slideAnimation != null
                            ? SlideTransition(
                                position: _slideAnimation!,
                                child: _buildEnhancedHeader(size, oliveGreen),
                              )
                            : _buildEnhancedHeader(size, oliveGreen),
                      )
                    : _buildEnhancedHeader(size, oliveGreen),
                _bounceAnimation != null
                    ? ScaleTransition(
                        scale: _bounceAnimation!,
                        child: _buildStatsSection(),
                      )
                    : _buildStatsSection(),
                _fadeAnimation != null
                    ? FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _buildContactInfoSection(),
                      )
                    : _buildContactInfoSection(),
                _fadeAnimation != null
                    ? FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _buildMenuSection(oliveGreen),
                      )
                    : _buildMenuSection(oliveGreen),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(Size size, Color oliveGreen) {
    return Container(
      height: size.height * 0.3,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    oliveGreen,
                    oliveGreen.withOpacity(0.9),
                    const Color(0xFF5A5C3A),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userProfile?['nama'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.work,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      userProfile?['role'] ?? 'Hunter',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Komisi',
                'Rp ${NumberFormat("#,##0", "id_ID").format(userProfile?['total_commission'] ?? 0)}',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Haunted Items',
                userProfile?['total_items_hunted'].toString() ?? '0',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Kontak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF77784A),
            ),
          ),
          const SizedBox(height: 15),
          _buildContactInfo(
            Icons.email,
            'Email',
            userProfile?['email'] ?? 'Tidak tersedia',
            () => _copyToClipboard(userProfile?['email'] ?? ''),
          ),
          const SizedBox(height: 10),
          _buildContactInfo(
            Icons.phone,
            'Nomor Telepon',
            userProfile?['telepon'] ?? 'Tidak tersedia',
            () => _copyToClipboard(userProfile?['telepon'] ?? ''),
          ),
          const SizedBox(height: 10),
          _buildContactInfo(
            Icons.location_on,
            'Alamat',
            userProfile?['alamat'] ?? 'Tidak tersedia',
            () => _copyToClipboard(userProfile?['alamat'] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
      IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF77784A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF77784A), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(Color oliveGreen) {
    final menuItems = [
      {
        'icon': Icons.logout,
        'title': 'Keluar Akun',
        'subtitle': 'Logout dari aplikasi',
        'color': Colors.red,
        'onTap': () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF77784A),
                ),
              ),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari akun?',
                style: TextStyle(color: Colors.black87),
              ),
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
                    'Keluar',
                    style: TextStyle(color: Color(0xFF77784A)),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            final result = await _authService.logout();
            if (result['success']) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PembeliScreen()),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'])),
                );
              }
            }
          }
        },
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            menuItems.map((item) => _buildEnhancedMenuItem(item)).toList(),
      ),
    );
  }

  Widget _buildEnhancedMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item['onTap'],
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$text disalin ke clipboard'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
