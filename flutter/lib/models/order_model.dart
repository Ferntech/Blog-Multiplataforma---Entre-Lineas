class OrderItemModel {
  final int id;
  final int? bookId;
  final String bookTitle;
  final String bookIsbn;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderItemModel({
    required this.id,
    this.bookId,
    required this.bookTitle,
    required this.bookIsbn,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num?)?.toInt(),
      bookTitle: json['book_title_snapshot']?.toString() ?? '',
      bookIsbn: json['book_isbn_snapshot']?.toString() ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final String customerName;
  final String billingAddress;
  final double totalAmount;
  final String currency;
  final String issuedAt;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.billingAddress,
    required this.totalAmount,
    required this.currency,
    required this.issuedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: (json['id'] as num).toInt(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      billingAddress: json['billing_address']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MXN',
      issuedAt: json['issued_at']?.toString() ?? '',
    );
  }
}

class OrderModel {
  final int id;
  final String orderReference;
  final String status;
  final double subtotal;
  final double shippingCost;
  final double totalAmount;
  final String currency;
  final String shippingRecipientName;
  final String shippingPhone;
  final String shippingAddressLine;
  final String shippingCity;
  final String shippingState;
  final String shippingPostalCode;
  final String shippingCountry;
  final String createdAt;
  final List<OrderItemModel> items;
  final InvoiceModel? invoice;

  const OrderModel({
    required this.id,
    required this.orderReference,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    required this.totalAmount,
    required this.currency,
    required this.shippingRecipientName,
    required this.shippingPhone,
    required this.shippingAddressLine,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPostalCode,
    required this.shippingCountry,
    required this.createdAt,
    required this.items,
    this.invoice,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return OrderModel(
      id: (json['id'] as num).toInt(),
      orderReference: json['order_reference']?.toString() ?? '',
      status: json['status']?.toString() ?? 'paid',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'MXN',
      shippingRecipientName: json['shipping_recipient_name']?.toString() ?? '',
      shippingPhone: json['shipping_phone']?.toString() ?? '',
      shippingAddressLine: json['shipping_address_line']?.toString() ?? '',
      shippingCity: json['shipping_city']?.toString() ?? '',
      shippingState: json['shipping_state']?.toString() ?? '',
      shippingPostalCode: json['shipping_postal_code']?.toString() ?? '',
      shippingCountry: json['shipping_country']?.toString() ?? 'México',
      createdAt: json['created_at']?.toString() ?? '',
      items: rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      invoice: json['invoice'] is Map<String, dynamic>
          ? InvoiceModel.fromJson(json['invoice'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'preparing':
        return 'Preparando';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      case 'refunded':
        return 'Reembolsado';
      default:
        return 'Pendiente';
    }
  }
}
