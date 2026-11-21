import 'package:material_ui/material_ui.dart';

import '../models/cart_model.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  ShoppingCartModel? _cart;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() => _loading = true);
    try {
      final data = await _cartService.obtenerCarrito();
      if (!mounted) return;
      setState(() {
        _cart = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _cambiarCantidad(CartItemModel item, int nuevaCantidad) async {
    try {
      final updated = nuevaCantidad <= 0
          ? await _cartService.eliminarArticulo(item.id)
          : await _cartService.actualizarCantidad(
              itemId: item.id,
              quantity: nuevaCantidad,
            );
      if (!mounted) return;
      setState(() => _cart = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Carrito')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_cart == null || _cart!.items.isEmpty)
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text('Tu carrito está vacío.'),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        if (_cart!.subtotal < 500)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFEF3C7),
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'Agrega \$${(500 - _cart!.subtotal).toStringAsFixed(2)} MXN más para obtener envío gratuito.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cart!.items.length,
                            itemBuilder: (context, index) {
                              final item = _cart!.items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    item.book.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '\$${item.book.price.toStringAsFixed(2)} c/u • Subtotal: \$${item.lineTotal.toStringAsFixed(2)} MXN',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => _cambiarCantidad(
                                          item,
                                          item.quantity - 1,
                                        ),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed:
                                            item.quantity < item.book.stock
                                                ? () => _cambiarCantidad(
                                                      item,
                                                      item.quantity + 1,
                                                    )
                                                : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _cambiarCantidad(item, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _rowResumen('Subtotal', _cart!.subtotal),
                                _rowResumen('Envío', _cart!.estimatedShipping),
                                const Divider(),
                                _rowResumen(
                                  'Total a pagar',
                                  _cart!.estimatedTotal,
                                  bold: true,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      final paid = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute<bool>(
                                          builder: (_) =>
                                              CheckoutPage(cart: _cart!),
                                        ),
                                      );
                                      if (paid == true && mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Continuar al pago'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _rowResumen(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${amount.toStringAsFixed(2)} MXN', style: style),
        ],
      ),
    );
  }
}
