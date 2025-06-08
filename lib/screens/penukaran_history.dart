import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PenukaranHistoryScreen extends StatefulWidget {
  const PenukaranHistoryScreen({super.key});

  @override
  State<PenukaranHistoryScreen> createState() => _PenukaranHistoryScreenState();
}

class _PenukaranHistoryScreenState extends State<PenukaranHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> penukaran = [];

  @override
  void initState() {
    super.initState();
    _fetchPenukaran();
  }

  Future<void> _fetchPenukaran() async {
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
        Uri.parse('http://10.0.2.2:8000/api/penukaran'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          penukaran = data is List ? data : [data];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat riwayat penukaran. Status: ${response.statusCode}';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: Container(
          width: 30, // Tambahkan ini
          height: 30,
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
        title: const Text(
          'Riwayat Penukaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF77784A),
        elevation: 4,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF77784A),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : penukaran.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history_toggle_off,
                            color: Colors.grey,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada riwayat penukaran.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListView.builder(
                        itemCount: penukaran.length,
                        itemBuilder: (context, index) {
                          final item = penukaran[index];
                          return Card(
                            color: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF77784A)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.redeem,
                                      color: Color(0xFF77784A),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['NAMA_MERCHANDISE'] ??
                                              'Nama Tidak Tersedia',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tanggal: ${item['TANGGAL_PENUKARAN'] ?? 'Tidak Tersedia'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kode Penukaran: ${item['KODE_PENUKARAN'] ?? 'Tidak Tersedia'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tanggal Diklaim: ${item['TANGGAL_DIKLAIM'] ?? 'Belum Diklaim'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                item['TANGGAL_DIKLAIM'] == null
                                                    ? Colors.orangeAccent
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF77784A)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item['POIN_DIGUNAKAN'] ?? '0'} Poin',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
