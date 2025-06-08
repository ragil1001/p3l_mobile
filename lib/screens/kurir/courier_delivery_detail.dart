import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../otentikasi/login.dart';

String _formatDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    final formatter = DateFormat('d MMMM y HH:mm', 'id_ID');
    return formatter.format(parsedDate);
  } catch (e) {
    return date;
  }
}

class CourierDeliveryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onStatusUpdated;

  const CourierDeliveryDetailScreen({
    super.key,
    required this.delivery,
    required this.onStatusUpdated,
  });

  @override
  _CourierDeliveryDetailScreenState createState() =>
      _CourierDeliveryDetailScreenState();
}

class _CourierDeliveryDetailScreenState
    extends State<CourierDeliveryDetailScreen> {
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

        print(
            'Sending request to update status: $newStatus for id_penjualan: ${widget.delivery['id_penjualan']}'); // Debug log

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
          print(
              'API Error: ${response.statusCode}, Response: ${response.body}'); // Debug log
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
        print('Exception during status update: $e'); // Debug log
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

  Color _getStatusColor(String status) {
    switch (status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
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
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: oliveGreen.withOpacity(0.7),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
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
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: const Text(
                                'Detail Pengiriman',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              expandedHeight: 100,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Card(
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
                              color: oliveGreen.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order ${widget.delivery['order_id']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A3C34),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              widget.delivery['status'])
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(
                                                widget.delivery['status'])
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(
                                              widget.delivery['status']),
                                          color: _getStatusColor(
                                              widget.delivery['status']),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.delivery['status'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                                widget.delivery['status']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Pelanggan',
                                  widget.delivery['customer_name']),
                              _buildAddressRow(
                                  'Alamat', widget.delivery['address']),
                              _buildDetailRow('Tanggal',
                                  _formatDate(widget.delivery['date'])),
                              _buildDetailRow(
                                  'Status', widget.delivery['status']),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Card(
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
                              color: oliveGreen.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Items in Delivery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3C34),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...(widget.delivery['items'] as List<dynamic>? ??
                                      [])
                                  .map((item) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    item['image'] as String,
                                                height: 60,
                                                width: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Shimmer.fromColors(
                                                  baseColor: Colors.grey[300]!,
                                                  highlightColor:
                                                      Colors.grey[100]!,
                                                  child: Container(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  height: 60,
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: Colors.grey,
                                                    size: 32,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF1A3C34),
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    item['price'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF7A7C52),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed:
                              widget.delivery['status'] == 'Sudah Diterima'
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
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A3C34),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3C34),
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
