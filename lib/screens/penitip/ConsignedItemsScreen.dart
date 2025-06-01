import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'ConsignedItemDetailScreen.dart'; // Import halaman detail

class ConsignedItemsScreen extends StatefulWidget {
  const ConsignedItemsScreen({super.key});

  @override
  _ConsignedItemsScreenState createState() => _ConsignedItemsScreenState();
}

class _ConsignedItemsScreenState extends State<ConsignedItemsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String? _selectedStatus;
  String _sortOrder = 'Terbaru';

  final List<Map<String, dynamic>> consignedItems = [
    {
      'id': '1',
      'title': 'Baju Metallica Tour 2009',
      'price': 'Rp. 16.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Tersedia',
      'description':
          'Kaos resmi dari tur Metallica tahun 2009. Kondisi baik, hanya dipakai beberapa kali.',
      'condition': 'Baik',
      'weight': '300 gr',
    },
    {
      'id': '2',
      'title': 'Jaket Vintage 90an',
      'price': 'Rp. 50.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Terjual',
      'description': 'Jaket vintage dari era 90an, kondisi sangat baik.',
      'condition': 'Sangat Baik',
      'weight': '500 gr',
    },
    {
      'id': '3',
      'title': 'Sepatu Sneakers',
      'price': 'Rp. 75.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Didonasikan',
      'description': 'Sepatu sneakers bekas dengan kondisi baik.',
      'condition': 'Baik',
      'weight': '400 gr',
    },
    {
      'id': '4',
      'title': 'Tas Kulit',
      'price': 'Rp. 100.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Tersedia',
      'description': 'Tas kulit second dengan kualitas sangat baik.',
      'condition': 'Sangat Baik',
      'weight': '600 gr',
    },
    {
      'id': '5',
      'title': 'Kemeja Flanel',
      'price': 'Rp. 30.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Terjual',
      'description': 'Kemeja flanel bekas, cocok untuk gaya kasual.',
      'condition': 'Baik',
      'weight': '350 gr',
    },
    {
      'id': '6',
      'title': 'Celana Jeans',
      'price': 'Rp. 40.000',
      'images': ['assets/images/hero-bg.png', 'assets/images/hero-bg.png'],
      'status': 'Dikembalikan',
      'description': 'Celana jeans bekas dengan kondisi baik.',
      'condition': 'Baik',
      'weight': '450 gr',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController!, curve: Curves.elasticOut));
    _animationController!.forward();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    List<Map<String, dynamic>> filteredItems = List.from(consignedItems);
    if (_selectedStatus != null) {
      filteredItems = filteredItems
          .where((item) => item['status'] == _selectedStatus)
          .toList();
    }
    if (_sortOrder == 'Terbaru') {
      filteredItems.sort((a, b) => b['id'].compareTo(a['id']));
    } else {
      filteredItems.sort((a, b) => a['id'].compareTo(b['id']));
    }
    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final oliveGreen = const Color(0xFF7A7C52);

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 8,
                backgroundColor: Colors.transparent,
                flexibleSpace: _animationController != null
                    ? AnimatedBuilder(
                        animation: _animationController!,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation!,
                            child: FadeTransition(
                              opacity: _fadeAnimation!,
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
                                        padding: const EdgeInsets.all(18.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      FadeInDown(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    800),
                                                        child: LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            double
                                                                availableWidth =
                                                                constraints
                                                                    .maxWidth;
                                                            String displayText =
                                                                _getDisplayText(
                                                                    availableWidth,
                                                                    _isScrolled);
                                                            double fontSize =
                                                                _getFontSize(
                                                                    _isScrolled,
                                                                    availableWidth);
                                                            return Text(
                                                              displayText,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize:
                                                                    fontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                height: 1.2,
                                                              ),
                                                              maxLines:
                                                                  _isScrolled
                                                                      ? 1
                                                                      : 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: true,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      if (!_isScrolled) ...[
                                                        const SizedBox(
                                                            height: 6),
                                                        FadeInDown(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      900),
                                                          child: const Text(
                                                            'Lihat barang yang Anda titipkan',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 13,
                                                              height: 1.3,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!_isScrolled) ...[
                                              const SizedBox(height: 16),
                                              FadeInUp(
                                                duration: const Duration(
                                                    milliseconds: 1000),
                                                child: Container(
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.95),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16),
                                                        child: Icon(
                                                          Icons.search,
                                                          color: Colors.grey,
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const Expanded(
                                                        child: TextField(
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                'Cari barang Anda...',
                                                            hintStyle:
                                                                TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 14,
                                                            ),
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            14),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
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
                      )
                    : Container(),
                expandedHeight: _isScrolled ? 90 : 180,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3C34),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Barang Saya yang Dititipkan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3C34),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_getFilteredItems().length} barang',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _isLoading ? 6 : _getFilteredItems().length,
                        itemBuilder: (context, index) {
                          if (_isLoading) {
                            return _buildShimmerCard();
                          } else {
                            final item = _getFilteredItems()[index];
                            return FadeInUp(
                              duration:
                                  Duration(milliseconds: 500 + (index * 100)),
                              child: ConsignedItemCard(
                                id: item['id'],
                                title: item['title'],
                                price: item['price'],
                                images: item['images'],
                                status: item['status'],
                                description: item['description'],
                                condition: item['condition'],
                                weight: item['weight'],
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ZoomIn(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3C34).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _showFilterSortDialog(context);
                  },
                  backgroundColor: const Color(0xFF1A3C34),
                  elevation: 0,
                  label: const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText(double availableWidth, bool isScrolled) {
    if (isScrolled) {
      return availableWidth < 250 ? 'Barang Saya' : 'Barang Saya Dititipkan';
    } else {
      if (availableWidth < 280) {
        return 'Barang Saya\nDititipkan';
      } else if (availableWidth < 350) {
        return 'Barang Saya Dititipkan';
      } else {
        return 'Barang Saya yang Dititipkan';
      }
    }
  }

  double _getFontSize(bool isScrolled, double availableWidth) {
    if (isScrolled) {
      return availableWidth < 250 ? 14 : 16;
    } else {
      if (availableWidth < 280) {
        return 18;
      } else if (availableWidth < 350) {
        return 19;
      } else {
        return 20;
      }
    }
  }

  void _showFilterSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C34),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Urutkan: Terbaru'),
                onTap: () {
                  setState(() {
                    _sortOrder = 'Terbaru';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Urutkan: Terlama'),
                onTap: () {
                  setState(() {
                    _sortOrder = 'Terlama';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_alt, color: Color(0xFF1A3C34)),
                title: const Text('Filter by Status'),
                onTap: () {
                  Navigator.pop(context);
                  _showStatusFilterDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C34),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tersedia'),
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Tersedia';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Terjual'),
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Terjual';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Didonasikan'),
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Didonasikan';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dikembalikan'),
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Dikembalikan';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Semua Status'),
                onTap: () {
                  setState(() {
                    _selectedStatus = null;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 100, color: Colors.grey),
                  const SizedBox(height: 4),
                  Container(height: 12, width: 80, color: Colors.grey),
                  const SizedBox(height: 4),
                  Container(height: 12, width: 60, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsignedItemCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final List<String> images;
  final String status;
  final String description;
  final String condition;
  final String weight;

  const ConsignedItemCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.images,
    required this.status,
    required this.description,
    required this.condition,
    required this.weight,
  });

  Color getStatusColor() {
    switch (status) {
      case 'Tersedia':
        return Colors.green;
      case 'Terjual':
        return Colors.blue;
      case 'Didonasikan':
        return Colors.orange;
      case 'Dikembalikan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConsignedItemDetailScreen(
              id: id,
              title: title,
              price: price,
              status: status,
              images: images,
              description: description,
              condition: condition,
              weight: weight,
            ),
          ),
        );
      },
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'consignedItemImage${id}_0',
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  images[0],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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
