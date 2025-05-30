import 'package:flutter/material.dart';
import 'pembeli.dart'; // Import PembeliScreen for navigation

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  _CatalogueScreenState createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  int _currentIndex = 1; // Set to 1 for CatalogueScreen
  String? _selectedCategory;

  // Dummy products based on screenshot
  final List<Map<String, String>> dummyProducts = List.generate(
    10,
    (index) => {
      'title': 'Fasidol Drops',
      'subcategory': 'Orlistat 120 mg',
      'price': 'Rp. 16.000',
      'volume': '15ml',
    },
  );

  // Daftar 10 kategori barang bekas
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Elektronik & Gadget', 'icon': Icons.devices},
    {'name': 'Pakaian & Aksesori', 'icon': Icons.shopping_bag},
    {'name': 'Perabotan Rumah Tangga', 'icon': Icons.home},
    {'name': 'Buku, Alat Tulis, & Peralatan Sekolah', 'icon': Icons.book},
    {'name': 'Hobi, Mainan, & Koleksi', 'icon': Icons.toys},
    {'name': 'Perlengkapan Bayi & Anak', 'icon': Icons.child_care},
    {'name': 'Otomotif & Aksesori', 'icon': Icons.directions_car},
    {'name': 'Perlengkapan Taman & Outdoor', 'icon': Icons.local_florist},
    {'name': 'Peralatan Kantor & Industri', 'icon': Icons.print},
    {'name': 'Kosmetik & Perawatan Diri', 'icon': Icons.spa},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Search Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFF1A3C34),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari Produk.....',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              // Dropdown for Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori Barang Bekas ReuseMart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3C34)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A3C34), width: 2),
                        ),
                      ),
                      hint: const Text('Pilih Kategori'),
                      value: _selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Row(
                            children: [
                              Icon(category['icon'], size: 20, color: const Color(0xFF1A3C34)),
                              const SizedBox(width: 8),
                              Text(category['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Product Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: dummyProducts.length,
                  itemBuilder: (context, index) {
                    final product = dummyProducts[index];
                    return ProductCard(
                      title: product['title']!,
                      subcategory: product['subcategory']!,
                      price: product['price']!,
                      volume: product['volume']!,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _currentIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _currentIndex = index;
      //       // Navigate to the selected screen
      //       if (index == 0) {
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(builder: (context) => const PembeliScreen()),
      //         );
      //       }
      //       // Add navigation for other indices if needed
      //     });
      //   },
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color(0xFF1A3C34),
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Product'),
      //     BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Transaksi'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      //   ],
      // ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subcategory;
  final String price;
  final String volume;

  const ProductCard({
    super.key,
    required this.title,
    required this.subcategory,
    required this.price,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    volume,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    subcategory,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3C34),
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