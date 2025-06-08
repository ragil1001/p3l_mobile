import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'hunter_commission_detail.dart';
import '../otentikasi/login.dart';
import '../../models/comission.dart';

class CommissionHistoryScreen extends StatefulWidget {
  const CommissionHistoryScreen({super.key});

  @override
  _CommissionHistoryScreenState createState() =>
      _CommissionHistoryScreenState();
}

class _CommissionHistoryScreenState extends State<CommissionHistoryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  List<Commission> _commissions = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();

    _fetchCommissions();
  }

  Future<void> _fetchCommissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
            _isLoading = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/hunter/komisi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Commission> fetchedCommissions = data.map((item) {
          return Commission(
            commissionId: item['KODE_PRODUK'] ?? 'Unknown ID',
            productName: item['product_name'] ?? 'Unknown Product',
            penitipName: item['penitip_name'] ?? 'Unknown Penitip',
            amount: int.parse(item['KOMISI_HUNTER'].toString()) ?? 0,
            date: item['commission_date'] ?? 'Unknown Date',
            status: item['status'] ?? 'Pending',
            imagePath: item['product_image'] != null &&
                    item['product_image'] !=
                        'http://10.0.2.2:8000/api/placeholder/60/60'
                ? 'http://10.0.2.2:8000/api/products/${item['KODE_PRODUK']}/thumbnail'
                : 'http://10.0.2.2:8000/api/placeholder/60/60',
          );
        }).toList();

        if (mounted) {
          setState(() {
            _commissions = fetchedCommissions;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        if (mounted) {
          setState(() {
            _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
            _isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat komisi: ${errorData['message'] ?? response.statusCode}';
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
          SnackBar(content: Text('Gagal memuat komisi: $e')),
        );
      }
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getDisplayText(double availableWidth) {
    return availableWidth < 280 ? 'Riwayat\nKomisi' : 'Riwayat Komisi';
  }

  double _getFontSize(double availableWidth) {
    return availableWidth < 280 ? 18 : 20;
  }

  Widget _buildCommissionList() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.elasticOut,
        )),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _commissions.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 200)),
              child: SlideInLeft(
                duration: Duration(milliseconds: 800 + (index * 150)),
                child: CommissionCard(
                  commission: _commissions[index],
                  index: index,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    if (_errorMessage != null) {
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
                'Gagal Memuat Komisi',
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
                Icons.monetization_on_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Belum ada riwayat komisi',
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
              'Mulai hunting untuk mendapatkan komisi!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
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
                    BoxShadow(
                      color: oliveGreen.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double availableWidth =
                                          constraints.maxWidth;
                                      String displayText =
                                          _getDisplayText(availableWidth);
                                      double fontSize =
                                          _getFontSize(availableWidth);

                                      return Text(
                                        displayText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        maxLines: availableWidth < 280 ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      '${_commissions.length} Komisi',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingShimmer()
                  : _commissions.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            _buildCommissionList(),
                            const SizedBox(height: 80),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommissionCard extends StatefulWidget {
  final Commission commission;
  final int index;

  const CommissionCard({
    super.key,
    required this.commission,
    required this.index,
  });

  @override
  _CommissionCardState createState() => _CommissionCardState();
}

class _CommissionCardState extends State<CommissionCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.commission.status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.commission.status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CommissionDetailScreen(commission: widget.commission),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF7A7C52).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCardHeader(),
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Divider(
                      height: 1,
                      color: Color(0xFF7A7C52),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildExpandedContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. ${widget.commission.commissionId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3C34),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(),
                                  color: _getStatusColor(),
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.commission.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.expand_circle_down_outlined,
                              color: const Color(0xFF7A7C52),
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.commission.date.split(' ')[0],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3C34),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Jumlah Komisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat("#,##0", "id_ID").format(widget.commission.amount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A7C52),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommissionDetailScreen(commission: widget.commission),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A7C52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7A7C52).withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A7C52).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 16,
                          color: Color(0xFF7A7C52),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.commission.penitipName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C34),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SlideInLeft(
                    duration: const Duration(milliseconds: 400),
                    child: CommissionItemWidget(
                      item: CommissionItem(
                        name: widget.commission.productName,
                        price:
                            'Rp ${NumberFormat("#,##0", "id_ID").format(widget.commission.amount)}',
                        imagePath: widget.commission.imagePath,
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
}

class CommissionItem {
  final String name;
  final String price;
  final String imagePath;

  CommissionItem({
    required this.name,
    required this.price,
    required this.imagePath,
  });
}

class CommissionItemWidget extends StatelessWidget {
  final CommissionItem item;

  const CommissionItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.grey,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3C34),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A7C52).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A7C52),
                    ),
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
