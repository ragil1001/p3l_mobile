import 'package:flutter/material.dart';
import 'riwayat_pesanan.dart'; // Import OrderHistoryScreen
import 'merchandise.dart'; // Import MerchandiseListScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Set to Profile tab by default

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Navigate to respective screens based on the tab index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/pembeli'); // Home tab
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/catalogue'); // Products tab
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transaksi'); // Transaksi tab
        break;
      case 3:
        // Already on Profile tab, no navigation needed
        break;
    }
  }

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
            // Green section with rounded bottom corners, raised higher
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                color: const Color(0xFF77784A),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Anton Sudrajat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '100 Poin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.grey[800],
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text('Transaksi Aktif', style: TextStyle(color: Colors.white)),
                                    Text('5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Card(
                              color: Colors.grey[800],
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text('Total Transaksi', style: TextStyle(color: Colors.white)),
                                    Text('12', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content below the green section, adjusted to maintain overlap
            Positioned(
              top: MediaQuery.of(context).size.height * 0.32,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 0),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Color(0xFF77784A)),
                        title: const Text('Tukar Poin dengan Merchandise'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MerchandiseListScreen()),
                          );
                        },
                      ),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.reorder, color: Color(0xFF77784A)),
                        title: const Text('Pesanan Anda'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFF77784A)),
                        title: const Text('Riwayat Pesanan'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          );
                        },
                      ),
                    ),
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Color(0xFF77784A)),
                        title: const Text('Keluar Akun'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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