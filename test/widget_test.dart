import 'package:flutter_test/flutter_test.dart';
import 'package:shopora/core/utils.dart';
import 'package:shopora/data/model/product_model.dart';

void main() {
  group('Product model', () {
    test('fromJson and toJson keep the same data', () {
      final json = {
        'id': 1,
        'title': 'Phone',
        'description': 'A good phone',
        'category': 'smartphones',
        'price': 499,
        'discountPercentage': 10.5,
        'rating': 4.2,
        'stock': 7,
        'brand': 'Apple',
        'thumbnail': 'https://example.com/t.png',
        'images': ['https://example.com/1.png'],
        'tags': ['phone'],
        'reviews': [
          {'rating': 5, 'comment': 'Great', 'reviewerName': 'A', 'date': ''},
        ],
      };

      final product = Product.fromJson(json);
      expect(product.price, 499.0);
      expect(product.reviews.first.comment, 'Great');
      expect(Product.fromJson(product.toJson()).title, 'Phone');
    });

    test('negative id means a locally created product', () {
      const product = Product(
        id: -123,
        title: 'Mine',
        description: 'Created in the app',
        category: 'beauty',
        price: 5,
      );
      expect(product.isLocal, isTrue);
      expect(product.subtitle, 'beauty');
    });
  });

  test('prettify turns a slug into words', () {
    expect(AppUtils.prettify('home-decoration'), 'Home Decoration');
  });
}
