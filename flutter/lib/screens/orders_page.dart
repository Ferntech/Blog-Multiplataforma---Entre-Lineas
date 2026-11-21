import 'package:material_ui/material_ui.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  late Future<List<OrderModel>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = _orderService.obtenerOrdenes();
  }

  Future<void> _recargarPedidos() async {
    setState(() {
      _futureOrders = _orderService.obtenerOrdenes();
    });
    await _futureOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: FutureBuilder<List<OrderModel>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _recargarPedidos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Todavía no has realizado ningún pedido.'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: RefreshIndicator(
                onRefresh: _recargarPedidos,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      color: AppColors.cardSurface,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.warmBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  order.orderReference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.inkNavy,
                                  ),
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text(order.statusLabel),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map(
                              (it) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '• ${it.quantity}x ${it.bookTitle} (\$${it.lineTotal.toStringAsFixed(2)} MXN)',
                                  style: const TextStyle(
                                    color: AppColors.inkBody,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.invoice != null
                                      ? 'Folio factura: ${order.invoice!.invoiceNumber}'
                                      : 'Comprobante digital',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.inkMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Total: \$${order.totalAmount.toStringAsFixed(2)} MXN',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amberPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (order.invoice != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.warmBorder,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 18,
                                      color: AppColors.amberPrimary,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Para descargar el archivo PDF de esta factura, ingresa a tu perfil desde la aplicación web de Entre Líneas.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkBody,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
