import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

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
                          'Riwayat Pesanan',
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
            // Order history content, no overlap
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15, // Start right after the green section
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Transaction 1 with 1 product
                    TransactionCard(
                      products: [
                        Product(
                          name: 'Baju Metallica Tour 2009',
                          price: 'Rp. 500.000',
                        ),
                      ],
                      total: 'Rp. 500.000',
                      status: 'Status Diproses',
                    ),
                    // Transaction 2 with 2 products
                    TransactionCard(
                      products: [
                        Product(
                          name: 'Baju Metallica Tour 2009',
                          price: 'Rp. 500.000',
                        ),
                        Product(
                          name: 'Baju Metallica Tour 2009',
                          price: 'Rp. 500.000',
                        ),
                      ],
                      total: 'Rp. 1.000.000',
                      status: 'Status Diproses',
                    ),
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

class TransactionCard extends StatelessWidget {
  final List<Product> products;
  final String total;
  final String status;

  const TransactionCard({
    super.key,
    required this.products,
    required this.total,
    required this.status,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Text(
              status,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF77784A),
              ),
            ),
            const SizedBox(height: 8),
            // Products list
            ...products.map((product) => ProductItem(product: product)).toList(),
            const SizedBox(height: 8),
            // Total
            Text(
              'Total ${products.length} produk: $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF77784A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final String price;

  Product({required this.name, required this.price});
}

class ProductItem extends StatelessWidget {
  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF77784A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price,
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
    );
  }
}