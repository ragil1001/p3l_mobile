import 'package:flutter/material.dart';

class MerchandiseListScreen extends StatelessWidget {
  const MerchandiseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background for the entire screen (white)
            Container(
              color: Colors.white,
            ),
            // Green section with rounded bottom corners, limited to header
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.15, // Limited to header height
                width: double.infinity,
                color: const Color(0xFF77784A),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Text(
                          'Daftar Merchandise',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer for symmetry
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Merchandise list content
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15, // Start right after the green section
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    MerchandiseCard(
                      productName: 'Baju Metallica Tour 2009',
                      price: 'Rp. 500.000',
                    ),
                    MerchandiseCard(
                      productName: 'Baju Metallica Tour 2009',
                      price: 'Rp. 500.000',
                    ),
                    // Add more dummy entries as needed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchandiseCard extends StatelessWidget {
  final String productName;
  final String price;

  const MerchandiseCard({
    super.key,
    required this.productName,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF77784A), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Placeholder image
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF77784A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF77784A),
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