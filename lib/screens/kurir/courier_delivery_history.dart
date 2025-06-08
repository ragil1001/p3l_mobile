import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import 'courier_delivery_detail.dart';
import '../otentikasi/login.dart';

String _formatDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    final wibDate = parsedDate.add(const Duration(hours: 7));
    final formatter = DateFormat('d MMMM y HH:mm', 'id_ID');
    return formatter.format(wibDate);
  } catch (e) {
    return date;
  }
}

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  _DeliveryHistoryScreenState createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  List<Map<String, dynamic>> _deliveries = [];

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

    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/kurir/transaksi-penjualan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        final List<Map<String, dynamic>> fetchedDeliveries = [];
        for (var transaction in data) {
          final detailResponse = await http.get(
            Uri.parse(
                'http://10.0.2.2:8000/api/kurir/transaksi-penjualan/${transaction['no_nota']}'),
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
                  ? 'http://10.0.2.2:8000/api/products/${p['product_id']}/thumbnail'
                  : 'http://10.0.2.2:8000/api/placeholder/60/60';
              print(
                  'Image URL for ${p['nama_barang']}: $imageUrl'); // Debug log
              return {
                'name': p['nama_barang'] as String? ?? 'Unknown Item',
                'price': p['harga_barang'] as String? ?? 'Rp0',
                'image': imageUrl,
                'product_id': p['product_id'] as String? ?? '',
              };
            }).toList();

            fetchedDeliveries.add({
              'id_penjualan': transaction['id_penjualan'],
              'order_id': transaction['no_nota'] as String? ?? 'Unknown ID',
              'customer_name':
                  detailData['nama_pembeli'] as String? ?? 'Unknown Buyer',
              'address': detailData['alamat'] as String? ?? 'Unknown Address',
              'status': transaction['status'] as String? ?? 'Unknown',
              'date':
                  transaction['tanggal_transaksi'] as String? ?? 'Unknown Date',
              'items': items,
            });
          } else {
            print(
                'Failed to fetch details for ${transaction['no_nota']}: ${detailResponse.statusCode}');
          }
        }

        if (mounted) {
          setState(() {
            _deliveries = fetchedDeliveries;
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat riwayat pengiriman: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error mengambil riwayat pengiriman: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getDisplayText(double availableWidth) {
    return availableWidth < 280 ? 'Riwayat\nPengiriman' : 'Riwayat Pengiriman';
  }

  double _getFontSize(double availableWidth) {
    return availableWidth < 280 ? 18 : 20;
  }

  Widget _buildDeliveryList() {
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
          itemCount: _deliveries.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 200)),
              child: SlideInLeft(
                duration: Duration(milliseconds: 800 + (index * 150)),
                child: DeliveryCard(
                  delivery: _deliveries[index],
                  index: index,
                  onStatusUpdated: _fetchDeliveries,
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
                'Gagal Memuat Pengiriman',
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
                Icons.local_shipping_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Belum ada riwayat pengiriman',
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
              'Mulai pengiriman untuk mencatat riwayat!',
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
                                      '${_deliveries.length} Pengiriman',
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
                  : _deliveries.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            _buildDeliveryList(),
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

class DeliveryCard extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final int index;
  final VoidCallback onStatusUpdated;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.index,
    required this.onStatusUpdated,
  });

  @override
  _DeliveryCardState createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<DeliveryCard>
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
    switch (widget.delivery['status']) {
      case 'Sudah Diterima':
        return Colors.green;
      case 'Sedang Dikirim':
        return Colors.blue;
      case 'Siap Dikirim':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.delivery['status']) {
      case 'Sudah Diterima':
        return Icons.check_circle;
      case 'Sedang Dikirim':
        return Icons.local_shipping;
      case 'Siap Dikirim':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  Future<void> _updateStatus() async {
    String? newStatus;
    String confirmationMessage;
    String actionText;

    if (widget.delivery['status'] == 'Siap Dikirim') {
      newStatus = 'Sedang Dikirim';
      confirmationMessage = 'Konfirmasi bahwa pengiriman telah dimulai?';
      actionText = 'Konfirmasi Pengiriman';
    } else if (widget.delivery['status'] == 'Sedang Dikirim') {
      newStatus = 'Sudah Diterima';
      confirmationMessage = 'Konfirmasi bahwa pengiriman telah diterima?';
      actionText = 'Konfirmasi Diterima';
    } else {
      return; // No action for 'Sudah Diterima' or other statuses
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Konfirmasi Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A7C52),
          ),
        ),
        content: Text(
          confirmationMessage,
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              actionText,
              style: TextStyle(color: Color(0xFF7A7C52)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return;
        }

        final response = await http.put(
          Uri.parse(
              'http://10.0.2.2:8000/api/kurir/transaksi-penjualan/${widget.delivery['id_penjualan']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'STATUS': newStatus,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            widget.delivery['status'] = newStatus;
          });
          widget.onStatusUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status diubah menjadi $newStatus'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          final responseBody = jsonDecode(response.body);
          final errorMessage = responseBody['message'] ??
              'Gagal memperbarui status: ${response.statusCode}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memperbarui status: $e'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                        'No Nota. ${widget.delivery['order_id']}',
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
                                  widget.delivery['status'],
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
                        _formatDate(widget.delivery['date']),
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
                      'Pembeli',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.delivery['customer_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A7C52),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Alamat',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.delivery['address'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3C34),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourierDeliveryDetailScreen(
                          delivery: widget.delivery,
                          onStatusUpdated: widget.onStatusUpdated,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF7A7C52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Color(0xFF7A7C52)),
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.delivery['status'] == 'Sudah Diterima'
                      ? null
                      : _updateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7A7C52),
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
                  child: Text(
                    widget.delivery['status'] == 'Siap Dikirim'
                        ? 'Konfirmasi Pengiriman'
                        : widget.delivery['status'] == 'Sedang Dikirim'
                            ? 'Konfirmasi Diterima'
                            : 'Selesai',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final items = widget.delivery['items'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInRight(
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
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          size: 16,
                          color: Color(0xFF7A7C52),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Items in Delivery',
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
                  ...items.asMap().entries.map((entry) {
                    final itemIndex = entry.key;
                    final item = entry.value;
                    return SlideInLeft(
                      duration: Duration(milliseconds: 400 + (itemIndex * 100)),
                      child: DeliveryItem(
                        item: DeliveryMapItem(
                          name: item['name'] as String,
                          price: item['price'] as String,
                          image: item['image'] as String,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryMapItem {
  final String name;
  final String price;
  final String image;

  DeliveryMapItem({
    required this.name,
    required this.price,
    required this.image,
  });
}

class DeliveryItem extends StatelessWidget {
  final DeliveryMapItem item;

  const DeliveryItem({super.key, required this.item});

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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.image,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.grey,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 60,
                width: 60,
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
