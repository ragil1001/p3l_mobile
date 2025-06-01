import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'transaction_detail.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<Transaction> _transactions = [];

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

    Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();

    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
    });

    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('Token: $token');
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/pembeli/transaksi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        String formatCurrency(int amount) {
          final formatter = NumberFormat('#,##0', 'id_ID');
          return 'Rp${formatter.format(amount)}';
        }

        final List<Transaction> fetchedTransactions = data.map((item) {
          final products = item['products'] as List<dynamic>? ?? [];
          final totalItemPrice = products.fold(
              0, (sum, p) => sum + (p['product_price_raw'] as int? ?? 0));
          final pointsDiscount = ((item['poin_digunakan'] as int? ?? 0) / 100).floor() * 10000;

          final Map<String, List<dynamic>> groupedProducts = {};
          for (var product in products) {
            final penitipName = product['nama_penitip'] as String? ?? 'Unknown Penitip';
            if (!groupedProducts.containsKey(penitipName)) {
              groupedProducts[penitipName] = [];
            }
            groupedProducts[penitipName]!.add(product);
          }

          final penitipItems = groupedProducts.entries.map((entry) {
            final penitipName = entry.key;
            final productsList = entry.value;
            final qcStaff = productsList.isNotEmpty
                ? productsList[0]['nama_qc'] as String? ?? 'Unknown QC'
                : 'Unknown QC';

            final items = productsList.map((p) => TransactionItem(
                  name: p['nama_barang'] as String? ?? 'Unknown Item',
                  price: p['harga_barang'] as String? ?? 'Rp0',
                  imagePath: p['image'] as String? ??
                      'http://10.0.2.2:8000/storage/images/default.jpg',
                )).toList();

            return PenitipItems(
              penitipName: penitipName,
              qcStaff: qcStaff,
              items: items,
            );
          }).toList();

          return Transaction(
            transactionId: item['no_nota'] as String? ?? 'Unknown ID',
            status: item['status'] as String? ?? 'Unknown',
            date: item['tanggal_transaksi'] as String? ?? 'Unknown Date',
            total: item['total_akhir'] as String? ?? 'Rp0',
            buyerName: item['nama_pembeli'] as String? ?? 'Unknown Buyer',
            buyerEmail: item['email_pembeli'] as String? ?? 'Unknown Email',
            buyerAddress: item['alamat'] as String? ?? 'Unknown Address',
            deliveryMethod: item['metode_pengiriman'] as String? ?? 'Unknown Method',
            penitipItems: penitipItems,
            paymentBreakdown: PaymentBreakdown(
              totalItemPrice: formatCurrency(totalItemPrice),
              shippingCost: item['ongkir'] as String? ?? 'Rp0',
              pointsUsed: item['poin_digunakan'] as int? ?? 0,
              discount: formatCurrency(pointsDiscount),
              pointsEarned: item['poin_diperoleh'] as int? ?? 0,
              finalTotal: item['total_akhir'] as String? ?? 'Rp0',
            ),
          );
        }).toList();

        setState(() {
          _transactions = fetchedTransactions;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        setState(() {
          _errorMessage = 'Sesi telah berakhir. Silakan login kembali.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat riwayat pesanan: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saat mengambil riwayat pesanan: $e';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getDisplayText(double availableWidth, bool isScrolled) {
    if (isScrolled) {
      return availableWidth < 250 ? 'Riwayat Pesanan' : 'Riwayat Pesanan';
    } else {
      if (availableWidth < 280) {
        return 'Riwayat\nPesanan';
      } else {
        return 'Riwayat Pesanan';
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

  Widget _buildTransactionList() {
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
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 200)),
              child: SlideInLeft(
                duration: Duration(milliseconds: 800 + (index * 150)),
                child: TransactionCard(
                  transaction: _transactions[index],
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
                'Gagal Memuat Pesanan',
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
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Belum ada riwayat pesanan',
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
              'Ayo mulai belanja di ReuseMart!',
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
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 8,
              backgroundColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xFF7A7C52).withOpacity(0.7),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.elasticOut,
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: Curves.easeInOut,
                      )),
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
                            BoxShadow(
                              color: oliveGreen.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
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
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 48),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FadeInDown(
                                            duration: const Duration(
                                                milliseconds: 800),
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                double availableWidth =
                                                    constraints.maxWidth;
                                                String displayText =
                                                    _getDisplayText(
                                                        availableWidth,
                                                        _isScrolled);
                                                double fontSize = _getFontSize(
                                                    _isScrolled,
                                                    availableWidth);

                                                return Text(
                                                  displayText,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: _isScrolled ? 1 : 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              child: Text(
                                                '${_transactions.length} Transaksi',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                  );
                },
              ),
              expandedHeight: _isScrolled ? 90 : 130,
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildLoadingShimmer()
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionList(),
            ),
          ],
        ),
      ),
    );
  }
}

class Transaction {
  final String transactionId;
  final String status;
  final String date;
  final String total;
  final String buyerName;
  final String buyerEmail;
  final String buyerAddress;
  final String deliveryMethod;
  final List<PenitipItems> penitipItems;
  final PaymentBreakdown paymentBreakdown;

  Transaction({
    required this.transactionId,
    required this.status,
    required this.date,
    required this.total,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerAddress,
    required this.deliveryMethod,
    required this.penitipItems,
    required this.paymentBreakdown,
  });
}

class PaymentBreakdown {
  final String totalItemPrice;
  final String shippingCost;
  final int pointsUsed;
  final String discount;
  final int pointsEarned;
  final String finalTotal;

  PaymentBreakdown({
    required this.totalItemPrice,
    required this.shippingCost,
    required this.pointsUsed,
    required this.discount,
    required this.pointsEarned,
    required this.finalTotal,
  });
}

class PenitipItems {
  final String penitipName;
  final String qcStaff;
  final List<TransactionItem> items;

  PenitipItems({
    required this.penitipName,
    required this.qcStaff,
    required this.items,
  });
}

class TransactionItem {
  final String name;
  final String price;
  final String imagePath;

  TransactionItem({
    required this.name,
    required this.price,
    required this.imagePath,
  });
}

class TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final int index;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  _TransactionCardState createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
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
    switch (widget.transaction.status.toLowerCase()) {
      case 'Selesai':
        return Colors.green;
      case 'Diproses':
        return Colors.orange;
      case 'Menunggu pembayaran':
        return Colors.red;
      case 'Pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status.toLowerCase()) {
      case 'Selesai':
        return Icons.check_circle;
      case 'Diproses':
        return Icons.hourglass_empty;
      case 'Menunggu pembayaran':
        return Icons.payment;
      case 'Pending':
        return Icons.pending;
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
                TransactionDetailScreen(transaction: widget.transaction),
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
                        'No. ${widget.transaction.transactionId}',
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
                                  widget.transaction.status,
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
                        'Tanggal Pesanan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.transaction.date.split(' ')[0],
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
                      'Total Pesanan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.transaction.total,
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
                      builder: (context) => TransactionDetailScreen(
                          transaction: widget.transaction),
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
          ...widget.transaction.penitipItems.asMap().entries.map((entry) {
            int penitipIndex = entry.key;
            PenitipItems penitip = entry.value;

            return FadeInUp(
              duration: Duration(milliseconds: 300 + (penitipIndex * 100)),
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
                            penitip.penitipName,
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
                    ...penitip.items.asMap().entries.map((itemEntry) {
                      int itemIndex = itemEntry.key;
                      TransactionItem item = itemEntry.value;

                      return SlideInLeft(
                        duration:
                            Duration(milliseconds: 400 + (itemIndex * 100)),
                        child: TransactionItemWidget(item: item),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class TransactionItemWidget extends StatelessWidget {
  final TransactionItem item;

  const TransactionItemWidget({super.key, required this.item});

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