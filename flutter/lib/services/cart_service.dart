import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_model.dart';
import '../models/order_model.dart';
import 'session_manager.dart';

typedef PayPalOrderData = Map<String, dynamic>;

class CartService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  void _actualizarContadorCarrito(ShoppingCartModel cart) {
    final totalUnidades = cart.items.fold<int>(
      0,
      (acumulado, item) => acumulado + item.quantity,
    );
    SessionManager.instance.updateBadges(cartCount: totalUnidades);
  }

  String _extraerMensajeError(dynamic data, String fallback) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return fallback;
  }

  Future<ShoppingCartModel> obtenerCarrito() async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .get(Uri.parse('$baseUrl/users/$uid/cart'))
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is Map<String, dynamic>) {
      final cart = ShoppingCartModel.fromJson(data);
      _actualizarContadorCarrito(cart);
      return cart;
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo obtener el carrito de compras'),
    );
  }

  Future<ShoppingCartModel> agregarLibro({
    required int bookId,
    int quantity = 1,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/users/$uid/cart/items'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'book_id': bookId,
            'quantity': quantity,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        data is Map<String, dynamic>) {
      final cart = ShoppingCartModel.fromJson(data);
      _actualizarContadorCarrito(cart);
      return cart;
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo agregar el libro al carrito'),
    );
  }

  Future<ShoppingCartModel> actualizarCantidad({
    required int itemId,
    required int quantity,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/users/$uid/cart/items/$itemId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is Map<String, dynamic>) {
      final cart = ShoppingCartModel.fromJson(data);
      _actualizarContadorCarrito(cart);
      return cart;
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo actualizar la cantidad'),
    );
  }

  Future<ShoppingCartModel> eliminarArticulo(int itemId) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .delete(Uri.parse('$baseUrl/users/$uid/cart/items/$itemId'))
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is Map<String, dynamic>) {
      final cart = ShoppingCartModel.fromJson(data);
      _actualizarContadorCarrito(cart);
      return cart;
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo eliminar el artículo del carrito'),
    );
  }

  Future<PayPalOrderData> crearOrdenPayPal({
    required String recipientName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
    String country = 'México',
    String? notes,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/users/$uid/checkout/paypal/create-order'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'shipping_recipient_name': recipientName,
            'shipping_phone': phone,
            'shipping_address_line': addressLine,
            'shipping_city': city,
            'shipping_state': state,
            'shipping_postal_code': postalCode,
            'shipping_country': country,
            'shipping_notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is Map<String, dynamic>) {
      return data;
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo iniciar la orden en PayPal'),
    );
  }

  Future<OrderModel> capturarOrdenPayPal({
    required String paypalOrderId,
    required String recipientName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
    String country = 'México',
    String? notes,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/users/$uid/checkout/paypal/capture-order'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'paypal_order_id': paypalOrderId,
            'shipping_recipient_name': recipientName,
            'shipping_phone': phone,
            'shipping_address_line': addressLine,
            'shipping_city': city,
            'shipping_state': state,
            'shipping_postal_code': postalCode,
            'shipping_country': country,
            'shipping_notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 18));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 201 && data is Map<String, dynamic>) {
      SessionManager.instance.updateBadges(cartCount: 0);
      return OrderModel.fromJson(data);
    }

    throw Exception(
      _extraerMensajeError(data, 'No se pudo capturar el pago en PayPal'),
    );
  }
}
