class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double mrp;
  final String unit;
  final String imageUrl;
  final List<String> images;
  final bool inStock;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.imageUrl,
    this.images = const [],
    this.inStock = true,
    this.description = '',
  });

  List<String> get allImages {
    final list = <String>[];
    if (imageUrl.isNotEmpty) list.add(imageUrl);
    for (final img in images) {
      if (img.isNotEmpty && !list.contains(img)) list.add(img);
    }
    return list;
  }

  double get discountPercent {
    if (mrp <= price || mrp <= 0) return 0;
    return (((mrp - price) / mrp) * 100).roundToDouble();
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    double? mrp,
    String? unit,
    String? imageUrl,
    List<String>? images,
    bool? inStock,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      inStock: inStock ?? this.inStock,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'imageUrl': imageUrl,
      'images': images,
      'inStock': inStock,
      'description': description,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    }
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '1 pc',
      imageUrl: json['imageUrl'] as String? ?? '',
      images: parsedImages,
      inStock: json['inStock'] as bool? ?? true,
      description: json['description'] as String? ?? '',
    );
  }
}
