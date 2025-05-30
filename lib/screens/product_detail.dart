import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String? label;

  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.price,
    this.label,
  });

  final List<Map<String, dynamic>> otherProducts = const [
    {'title': 'Paracetamol 500mg', 'price': 'Rp. 10.000'},
    {'title': 'Ibuprofen 200mg', 'price': 'Rp. 12.000'},
    {'title': 'Amoxicillin 250mg', 'price': 'Rp. 15.000'},
  ];

  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 100),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          Text(
                            label!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A3C34),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Biogesic Paracetamol adalah obat yang digunakan untuk meredakan demam dan nyeri ringan hingga sedang, seperti sakit kepala, nyeri otot, atau nyeri gigi. Produk ini aman digunakan sesuai dosis yang dianjurkan.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Produk Lainnya',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: otherProducts.map((product) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  width: 200,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                product['title'],
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                product['price'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1A3C34),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 80), // Space for footer button
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3C34)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proceeding to web purchase')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3C34),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Lanjutkan Pembelian di Web', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}