/// One customer review of a product.
class Review {
  final int rating;
  final String comment;
  final String reviewerName;
  final String date;

  const Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'reviewerName': reviewerName,
    'date': date,
  };
}

/// A product from the DummyJSON API (or one created locally).
class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final List<String> tags;
  final List<Review> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.brand = '',
    this.thumbnail = '',
    this.images = const [],
    this.tags = const [],
    this.reviews = const [],
  });

  /// Products created inside the app get a negative id,
  /// so they never clash with real API ids (which are positive).
  bool get isLocal => id < 0;

  /// Brand if it exists, otherwise the category.
  String get subtitle => brand.isNotEmpty ? brand : category;

  /// Picture shown in lists. Falls back to the first gallery image.
  String get mainImage => thumbnail.isNotEmpty
      ? thumbnail
      : (images.isNotEmpty ? images.first : '');

  /// Images for the detail gallery, never empty if any picture exists.
  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    return mainImage.isNotEmpty ? [mainImage] : [];
  }

  // Hive gives back Map<dynamic, dynamic>, so every nested map/list is
  // converted with Map<String, dynamic>.from / List.from to be safe.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      images: List<String>.from(json['images'] as List? ?? const []),
      tags: List<String>.from(json['tags'] as List? ?? const []),
      reviews: (json['reviews'] as List? ?? const [])
          .map((r) => Review.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'brand': brand,
    'thumbnail': thumbnail,
    'images': images,
    'tags': tags,
    'reviews': reviews.map((r) => r.toJson()).toList(),
  };

  /// Only the fields our Add/Edit form changes (sent to POST/PUT).
  Map<String, dynamic> toRequestBody() => {
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'thumbnail': thumbnail,
  };

  Product copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    double? price,
    String? thumbnail,
    List<String>? images,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage,
      rating: rating,
      stock: stock,
      brand: brand,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      tags: tags,
      reviews: reviews,
    );
  }
}

/// One page of results from the API plus the total count,
/// used to know whether more pages exist.
class ProductPage {
  final List<Product> products;
  final int total;

  const ProductPage({required this.products, required this.total});
}
