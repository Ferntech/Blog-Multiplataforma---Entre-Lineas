import 'book_model.dart';

class CartItemModel {
  final int id;
  final int bookId;
  final int quantity;
  final double lineTotal;
  final BookModel book;

  const CartItemModel({
    required this.id,
    required this.bookId,
    required this.quantity,
    required this.lineTotal,
    required this.book,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
      book: BookModel.fromJson(json['book'] as Map<String, dynamic>),
    );
  }
}

class ShoppingCartModel {
  final int id;
  final int userId;
  final String status;
  final List<CartItemModel> items;
  final double subtotal;
  final double estimatedShipping;
  final double estimatedTotal;
  final String currency;

  const ShoppingCartModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.estimatedShipping,
    required this.estimatedTotal,
    this.currency = 'MXN',
  });

  factory ShoppingCartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ShoppingCartModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status']?.toString() ?? 'active',
      items: rawItems
          .map((i) => CartItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      estimatedShipping:
          (json['estimated_shipping'] as num?)?.toDouble() ?? 0.0,
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MXN',
    );
  }

  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);
}
