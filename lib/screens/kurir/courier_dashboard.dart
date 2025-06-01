import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';

// Model untuk data pengiriman
class Delivery {
  final String id;
  final String orderNumber;
  final String recipientName;
  final String address;
  String status;
  final List<String> items;

  Delivery({
    required this.id,
    required this.orderNumber,
    required this.recipientName,
    required this.address,
    required this.status,
    required this.items,
  });
}

// Halaman utama kurir
class CourierDashboard extends StatefulWidget {
  @override
  _CourierDashboardState createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  int _selectedIndex = 0;
  List<Delivery> deliveries = [
    Delivery(
      id: '1',
      orderNumber: 'ORD001',
      recipientName: 'John Doe',
      address: 'Jl. Merdeka No. 123, Jakarta',
      status: 'Dalam Pengiriman',
      items: ['Baju Metallica Tour 2009', 'Jaket Vintage 90an'],
    ),
    Delivery(
      id: '2',
      orderNumber: 'ORD002',
      recipientName: 'Jane Smith',
      address: 'Jl. Sudirman No. 456, Bandung',
      status: 'Sudah Diterima',
      items: ['Sepatu Sneakers'],
    ),
    Delivery(
      id: '3',
      orderNumber: 'ORD003',
      recipientName: 'Alice Johnson',
      address: 'Jl. Gatot Subroto No. 789, Surabaya',
      status: 'Menunggu Pengambilan',
      items: ['Tas Kulit', 'Kemeja Flanel'],
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateDeliveryStatus(String id, String newStatus) {
    setState(() {
      final index = deliveries.indexWhere((d) => d.id == id);
      if (index != -1) {
        deliveries[index].status = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ActiveDeliveriesScreen(
        deliveries:
            deliveries.where((d) => d.status != 'Sudah Diterima').toList(),
        onUpdateStatus: _updateDeliveryStatus,
      ),
      DeliveryHistoryScreen(
        deliveries:
            deliveries.where((d) => d.status == 'Sudah Diterima').toList(),
      ),
      CourierProfileScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFF77784A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Layar untuk pengiriman aktif
class ActiveDeliveriesScreen extends StatelessWidget {
  final List<Delivery> deliveries;
  final Function(String, String) onUpdateStatus;

  const ActiveDeliveriesScreen({
    Key? key,
    required this.deliveries,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Deliveries'),
        backgroundColor: Color(0xFF77784A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: DeliveryCard(
              delivery: deliveries[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryDetailScreen(
                      delivery: deliveries[index],
                      onUpdateStatus: onUpdateStatus,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Layar untuk riwayat pengiriman
class DeliveryHistoryScreen extends StatelessWidget {
  final List<Delivery> deliveries;

  const DeliveryHistoryScreen({
    Key? key,
    required this.deliveries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery History'),
        backgroundColor: Color(0xFF77784A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: DeliveryCard(
              delivery: deliveries[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryDetailScreen(
                      delivery: deliveries[index],
                      onUpdateStatus: (_, __) {}, // Tidak ada update di history
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Widget untuk kartu pengiriman
class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;

  const DeliveryCard({
    Key? key,
    required this.delivery,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(delivery.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(delivery.status),
            color: _getStatusColor(delivery.status),
          ),
        ),
        title: Text(delivery.orderNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(delivery.recipientName),
            Text(delivery.address),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(delivery.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            delivery.status,
            style: TextStyle(color: _getStatusColor(delivery.status)),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sudah Diterima':
        return Colors.green;
      case 'Dalam Pengiriman':
        return Colors.orange;
      case 'Menunggu Pengambilan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Sudah Diterima':
        return Icons.check_circle;
      case 'Dalam Pengiriman':
        return Icons.local_shipping;
      case 'Menunggu Pengambilan':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }
}

// Layar detail pengiriman
class DeliveryDetailScreen extends StatelessWidget {
  final Delivery delivery;
  final Function(String, String) onUpdateStatus;

  const DeliveryDetailScreen({
    Key? key,
    required this.delivery,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Details'),
        backgroundColor: Color(0xFF77784A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Number: ${delivery.orderNumber}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Recipient: ${delivery.recipientName}'),
            Text('Address: ${delivery.address}'),
            Text('Status: ${delivery.status}'),
            SizedBox(height: 16),
            Text('Items:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...delivery.items.map((item) => Text('- $item')).toList(),
            SizedBox(height: 24),
            if (delivery.status != 'Sudah Diterima')
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Konfirmasi'),
                      content: Text(
                          'Apakah Anda yakin ingin menandai pengiriman ini sebagai Sudah Diterima?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Tidak'),
                        ),
                        TextButton(
                          onPressed: () {
                            onUpdateStatus(delivery.id, 'Sudah Diterima');
                            Navigator.pop(context);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Status pengiriman diperbarui')),
                            );
                          },
                          child: Text('Ya'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Tandai Sudah Diterima'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF77784A),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Layar profil kurir
class CourierProfileScreen extends StatefulWidget {
  @override
  _CourierProfileScreenState createState() => _CourierProfileScreenState();
}

class _CourierProfileScreenState extends State<CourierProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please login again.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user_type'] == 'kurir') {
          setState(() {
            userProfile = {
              'nama': data['user']['nama'],
              'email': data['user']['email'],
              'telepon': data['user']['telepon'] ?? 'Tidak tersedia',
              'alamat': data['user']['alamat'] ?? 'Tidak tersedia',
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Profile only available for kurir';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage =
              'Failed to load profile: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header profil
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF77784A), Color(0xFF5A5C3A)],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Color(0xFF77784A)),
                ),
                SizedBox(height: 16),
                Text(
                  userProfile!['nama'],
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  userProfile!['email'],
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Informasi kontak
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informasi Kontak',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Telepon'),
                  subtitle: Text(userProfile!['telepon']),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Alamat'),
                  subtitle: Text(userProfile!['alamat']),
                ),
              ],
            ),
          ),
          // Menu logout
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Keluar Akun'),
                  onTap: () async {
                    final result = await _authService.logout();
                    if (result['success']) {
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
