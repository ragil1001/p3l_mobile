import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

const String baseUrl = 'http://10.0.2.2:8000/api'; // Perbarui ke 10.0.2.2

class CatalogueScreen extends StatefulWidget {
  final String? selectedCategory; // Tambahkan parameter untuk kategori yang dipilih

  const CatalogueScreen({super.key, this.selectedCategory});

  @override
  _CatalogueScreenState createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedSubcategory;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<dynamic> _products = [];

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Elektronik & Gadget',
      'icon': Icons.devices,
      'subcategories': ['Smartphone', 'Laptop', 'Aksesori Elektronik']
    },
    {
      'name': 'Pakaian & Aksesori',
      'icon': Icons.shopping_bag,
      'subcategories': ['Pakaian Pria', 'Pakaian Wanita', 'Aksesori Fashion']
    },
    {
      'name': 'Perabotan Rumah Tangga',
      'icon': Icons.home,
      'subcategories': ['Furniture', 'Dekorasi', 'Peralatan Dapur']
    },
    {
      'name': 'Buku, Alat Tulis, & Peralatan Sekolah',
      'icon': Icons.book,
      'subcategories': ['Buku Pelajaran', 'Alat Tulis', 'Peralatan Sekolah']
    },
    {
      'name': 'Hobi, Mainan, & Koleksi',
      'icon': Icons.toys,
      'subcategories': ['Mainan Anak', 'Koleksi Barang', 'Peralatan Hobi']
    },
    {
      'name': 'Perlengkapan Bayi & Anak',
      'icon': Icons.child_care,
      'subcategories': ['Pakaian Bayi', 'Mainan Bayi', 'Peralatan Bayi']
    },
    {
      'name': 'Otomotif & Aksesori',
      'icon': Icons.directions_car,
      'subcategories': ['Sparepart', 'Aksesori Mobil', 'Aksesori Motor']
    },
    {
      'name': 'Perlengkapan Taman & Outdoor',
      'icon': Icons.local_florist,
      'subcategories': [
        'Peralatan Taman',
        'Dekorasi Outdoor',
        'Peralatan Camping'
      ]
    },
    {
      'name': 'Peralatan Kantor & Industri',
      'icon': Icons.print,
      'subcategories': ['Peralatan Kantor', 'Mesin Industri', 'Alat Berat']
    },
    {
      'name': 'Kosmetik & Perawatan Diri',
      'icon': Icons.spa,
      'subcategories': ['Makeup', 'Perawatan Kulit', 'Perawatan Rambut']
    },
  ];

  @override
  void initState() {
    super.initState();

    // Jika ada kategori yang dipilih dari homepage, gunakan sebagai filter awal
    _selectedCategory = widget.selectedCategory;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));

    _animationController!.forward();

    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
    });

    _fetchProducts();
  }

  Future<bool> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Connectivity Check Error: $e');
      return false; // Default ke false jika ada error
    }
  }

  Future<void> _fetchProducts() async {
    if (!await _checkConnectivity()) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        print('API Response: $jsonResponse'); // Logging respons API
        if (jsonResponse['success'] && jsonResponse['data'] is List) {
          setState(() {
            _products = jsonResponse['data'].map((product) {
              // Pastikan 'images' adalah list string yang valid
              var images = product['images'];
              if (images is List && images.isNotEmpty) {
                return {
                  ...product,
                  'images': images
                      .whereType<String>()
                      .map((img) => img.startsWith('http') ? img : '$baseUrl$img')
                      .toList(),
                };
              }
              return {...product, 'images': ['']}; // Fallback ke string kosong
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch Products Error: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat produk: $e')),
      );
    }
  }

  // Filter produk berdasarkan kategori yang dipilih
  List<dynamic> get _filteredProducts {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      String productCategory = product['category']?.toString().toLowerCase() ?? '';
      String selectedCategoryLower = _selectedCategory!.toLowerCase();
      return productCategory == selectedCategoryLower;
    }).toList();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
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
                flexibleSpace: AnimatedBuilder(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                FadeInDown(
                                                  duration: const Duration(milliseconds: 800),
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      double availableWidth = constraints.maxWidth;
                                                      String displayText = _getDisplayText(availableWidth, _isScrolled);
                                                      double fontSize = _getFontSize(_isScrolled, availableWidth);

                                                      return Text(
                                                        displayText,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: fontSize,
                                                          fontWeight: FontWeight.bold,
                                                          height: 1.2,
                                                        ),
                                                        maxLines: _isScrolled ? 1 : 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        softWrap: true,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                if (!_isScrolled) ...[
                                                  const SizedBox(height: 6),
                                                  FadeInDown(
                                                    duration: const Duration(milliseconds: 900),
                                                    child: Text(
                                                      'Temukan produk preloved berkualitas dengan harga terjangkau',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                        height: 1.3,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
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
                                          duration: const Duration(milliseconds: 1000),
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Colors.grey,
                                                    size: 22,
                                                  ),
                                                ),
                                                const Expanded(
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                      hintText: 'Cari produk impianmu...',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                ),
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
                              'Katalog ReuseMart',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3C34),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredProducts.length} produk',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isLoading
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: 6,
                              itemBuilder: (context, index) {
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
                                          height: 70,
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 16,
                                                width: 100,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              SizedBox(
                                                height: 12,
                                                width: 80,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              SizedBox(
                                                height: 12,
                                                width: 60,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                print('Rendering Product $index: $product'); // Logging produk
                                return FadeInUp(
                                  duration: Duration(milliseconds: 500 + (index * 100)),
                                  child: ProductCard(
                                    id: product['id'].toString(),
                                    title: product['name'] ?? 'Produk Tanpa Nama',
                                    subcategory: product['subcategory'] ?? '',
                                    price: 'Rp ${product['price']?.toStringAsFixed(0) ?? '0'}',
                                    volume: product['volume'] ?? 'N/A',
                                    condition: product['condition'] ?? 'N/A',
                                    weight: product['weight']?.toString() ?? 'N/A',
                                    warranty: product['warranty_date'] ?? '–',
                                    description: product['description'] ?? '',
                                    images: product['images'] as List<String>,
                                  ),
                                );
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
      return availableWidth < 250 ? 'Jelajahi Barang' : 'Jelajahi Barang Bekas';
    } else {
      if (availableWidth < 280) {
        return 'Jelajahi Barang\nBekas Terbaik';
      } else if (availableWidth < 350) {
        return 'Jelajahi Barang Bekas Terbaik';
      } else {
        return 'Jelajahi Barang Bekas Terbaik';
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
                title: const Text('Sort by Price: Low to High'),
                onTap: () {
                  setState(() {
                    _products.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: Color(0xFF1A3C34)),
                title: const Text('Sort by Price: High to Low'),
                onTap: () {
                  setState(() {
                    _products.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_alt, color: Color(0xFF1A3C34)),
                title: const Text('Filter by Category'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryFilterDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C34),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ExpansionTile(
                      leading: Icon(category['icon'], color: const Color(0xFF1A3C34)),
                      title: Text(category['name']),
                      children: (category['subcategories'] as List<String>)
                          .map((subcategory) {
                        return ListTile(
                          title: Text(subcategory),
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name'];
                              _selectedSubcategory = subcategory;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear, color: Color(0xFF1A3C34)),
                  title: const Text('Clear Filter'),
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedSubcategory = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final String id;
  final String title;
  final String subcategory;
  final String price;
  final String volume;
  final String condition;
  final String weight;
  final String warranty;
  final String description;
  final List<String> images;

  const ProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.subcategory,
    required this.price,
    required this.volume,
    required this.condition,
    required this.weight,
    required this.warranty,
    required this.description,
    required this.images,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String _formatRupiah(String price) {
    final number = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'Rp ${NumberFormat("#,##0", "id_ID").format(number)}';
  }
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: widget.id),
      ),
    );
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'productImage${widget.id}_0',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: widget.images.isNotEmpty &&
                          widget.images[0].isNotEmpty &&
                          widget.images[0].startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: widget.images[0],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            print('Image Load Error for $url: $error');
                            return Image.asset(
                              'assets/images/placeholder.png',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/placeholder.png',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.volume,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      widget.subcategory,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(widget.price),
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
      ),
    );
  }
}