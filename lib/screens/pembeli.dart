import 'package:flutter/material.dart';
import 'catalogue_screen.dart'; // Import CatalogueScreen
import 'product_detail.dart'; // Import ProductDetailScreen
import 'profile.dart'; // Import ProfileScreen

class PembeliScreen extends StatefulWidget {
  const PembeliScreen({super.key});

  @override
  _PembeliScreenState createState() => _PembeliScreenState();
}

class _PembeliScreenState extends State<PembeliScreen> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: // Home Tab
        return SingleChildScrollView(
          child: Column(
            children: const [
              HeroSection(),
              ProductSection(),
              CategorySection(),
              WhyChooseReuseMartSection(),
              ThreeHorizontalCard(),
              AboutUsSection(),
              FooterSection(),
            ],
          ),
        );
      case 1: // Products Tab
        return const CatalogueScreen();
      case 2: // Cart Tab
        return const Center(child: Text('Transaksi Screen'));
      case 3: // Profile Tab
        return const ProfileScreen(); // Use ProfileScreen here
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Navigate to respective screens based on the tab index
          switch (index) {
            case 0:
              // Already on Home tab, no navigation needed
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/pembeli_dashboard/catalogue'); // Products tab
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/pembeli_dashboard/transaksi'); // Transaksi tab
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/pembeli_dashboard/profile'); // Profile tab
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A3C34),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Product'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/hero-bg.png'),
          fit: BoxFit.cover,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0xFF77784A), // Gradient opacity for upper hero-bg
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari Produk.....',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
          const SizedBox(height: 20),
          const Text(
            'Temukan Kesempatan Baru\ndalam Barang Lama',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('200+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A3C34))),
                      Text('Pembeli Puas', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('100+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A3C34))),
                      Text('Dipercaya Pentip', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('100%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A3C34))),
                      Text('Barang Layak Pakai', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  const ProductSection({super.key});

  final List<Map<String, String>> products = const [
    {'title': 'Orlistat 120 mg', 'price': 'Rp. 16.000'},
    {'title': 'Fasidol Drops', 'price': 'Rp. 20.000'},
    {'title': 'Paracetamol', 'price': 'Rp. 10.000'},
    {'title': 'Amoxicillin', 'price': 'Rp. 25.000'},
    {'title': 'Ibuprofen', 'price': 'Rp. 15.000'},
    {'title': 'Cetirizine', 'price': 'Rp. 12.000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan Barang Berkualitas dan Mudah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3C34),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: (products.length / 2).ceil(),
              itemBuilder: (context, index) {
                final int firstProductIndex = index * 2;
                final int secondProductIndex = firstProductIndex + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ProductCard(
                        title: products[firstProductIndex]['title']!,
                        price: products[firstProductIndex]['price']!,
                      ),
                      if (secondProductIndex < products.length)
                        ProductCard(
                          title: products[secondProductIndex]['title']!,
                          price: products[secondProductIndex]['price']!,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjutkan Pembelian di Website Kami',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A3C34),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String price;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150,
        color: Colors.white,
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
                    color: Colors.black.withOpacity(0.05),
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

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Elektronik & Gadget', 'icon': Icons.devices},
    {'name': 'Perabotan Rumah Tangga', 'icon': Icons.home},
    {'name': 'Pakaian & Aksesori', 'icon': Icons.shopping_bag},
    {'name': 'Buku, Alat Tulis,\n& Peralatan Sekolah', 'icon': Icons.book},
    {'name': 'Hobi, Mainan, & Koleksi', 'icon': Icons.toys},
    {'name': 'Perlengkapan Bayi & Anak', 'icon': Icons.child_care},
    {'name': 'Otomotif & Aksesori', 'icon': Icons.directions_car},
    {'name': 'Perlengkapan\nTaman & Outdoor', 'icon': Icons.local_florist},
    {'name': 'Peralatan\nKantor & Industri', 'icon': Icons.print},
    {'name': 'Kosmetik & Perawatan Diri', 'icon': Icons.spa},
  ];

  List<List<Map<String, dynamic>>> _groupCategories() {
    List<List<Map<String, dynamic>>> grouped = [];
    for (int i = 0; i < categories.length; i += 2) {
      grouped.add(categories.sublist(i, i + 2 > categories.length ? categories.length : i + 2));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Map<String, dynamic>>> groupedCategories = _groupCategories();
    const double cardWidth = 180.0; // Fixed width for compactness, adjusted for content

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Barang Bekas ReuseMart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3C34),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120, // Fixed height for the category section (two cards stacked)
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: groupedCategories.length,
              itemBuilder: (context, index) {
                final pair = groupedCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: pair.map((category) {
                      return SizedBox(
                        width: cardWidth, // Use fixed width for each category card
                        height: 60, // Fixed height for each category card
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(category['icon'], size: 24, color: const Color(0xFF1A3C34)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category['name'],
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WhyChooseReuseMartSection extends StatelessWidget {
  const WhyChooseReuseMartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        'Mengapa Memilih ReuseMart',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A3C34),
        ),
      ),
    );
  }
}

class ThreeHorizontalCard extends StatelessWidget {
  const ThreeHorizontalCard({super.key});

  final List<Map<String, dynamic>> cardsData = const [
    {
      'title': 'Ramah Lingkungan',
      'description': 'Mengurangi limbah dengan barang bekas',
      'icon': Icons.eco,
    },
    {
      'title': 'Hemat Biaya',
      'description': 'Harga terjangkau, kualitas terjamin',
      'icon': Icons.monetization_on,
    },
    {
      'title': 'Transaksi Aman',
      'description': 'Verifikasi ketat untuk keamanan',
      'icon': Icons.security,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;
    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: cardsData.map((data) {
          return Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(data['icon'], size: 36, color: Color(0xFF1A3C34)),
                    const SizedBox(height: 8),
                    Text(
                      data['title'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/hero-bg.jpg'),
          fit: BoxFit.cover,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black, // Gradient opacity transparent to black
          ],
          stops: [0.4, 1.0], // Start black gradient where text begins
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ingin Tahu Lebih Banyak?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pelajari lebih lanjut tentang ReuseMart',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to About Us')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A3C34),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Lanjutkan Pembelian di Website Kami', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF1A3C34),
      child: const Column(
        children: [
          Text(
            'ReUseMart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ReuseMart adalah platform jual beli barang bekas terpercaya di Yogyakarta, mendukung transaksi mudah dan ramah lingkungan. anda bebas buat teks disini, untuk copyright dll biarin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            'Â© 2025 ReuseMart. All Rights Reserved.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 12, color: Colors.white70, decoration: TextDecoration.underline),
              ),
              SizedBox(width: 16),
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 12, color: Colors.white70, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}