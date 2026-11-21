import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'orders_page.dart';

class CheckoutPage extends StatefulWidget {
  final ShoppingCartModel cart;

  const CheckoutPage({super.key, required this.cart});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final CartService _cartService = CartService();

  bool _processing = false;
  String? _paypalOrderId;
  String? _approveUrl;

  @override
  void initState() {
    super.initState();
    final user = SessionManager.instance.currentUser;
    if (user != null) {
      _recipientCtrl.text = user.fullName;
      _phoneCtrl.text = user.phone ?? '';
      _addressCtrl.text = user.addressLine ?? '';
      _cityCtrl.text = user.city ?? '';
      _stateCtrl.text = user.state ?? '';
      _postalCtrl.text = user.postalCode ?? '';
    }
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirVentanaPayPal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _iniciarOrdenPayPal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);

    try {
      final orderInfo = await _cartService.crearOrdenPayPal(
        recipientName: _recipientCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        postalCode: _postalCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final ppId = orderInfo['paypal_order_id']?.toString() ?? '';
      final url = orderInfo['approve_url']?.toString() ?? '';

      if (!mounted) return;
      setState(() {
        _paypalOrderId = ppId;
        _approveUrl = url;
      });

      if (url.isNotEmpty) {
        await _abrirVentanaPayPal(url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _capturarPagoPayPal() async {
    if (_paypalOrderId == null) return;
    setState(() => _processing = true);

    try {
      final order = await _cartService.capturarOrdenPayPal(
        paypalOrderId: _paypalOrderId!,
        recipientName: _recipientCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        postalCode: _postalCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Pago capturado con éxito!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Referencia del pedido: ${order.orderReference}'),
              Text(
                'Folio de factura: ${order.invoice?.invoiceNumber ?? 'Generado'}',
              ),
              Text(
                'Total pagado: \$${order.totalAmount.toStringAsFixed(2)} MXN',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.amberPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu factura electrónica ha sido registrada. Para descargar el archivo PDF, visita tu perfil desde la aplicación web de Entre Líneas.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const OrdersPage()),
                );
              },
              child: const Text('Ver mis pedidos'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordenCreada = _paypalOrderId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Dirección de envío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientCtrl,
                    enabled: !ordenCreada,
                    decoration: const InputDecoration(
                      labelText: 'Nombre quien recibe',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    enabled: !ordenCreada,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    enabled: !ordenCreada,
                    decoration: const InputDecoration(
                      labelText: 'Calle, número y colonia',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          enabled: !ordenCreada,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateCtrl,
                          enabled: !ordenCreada,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalCtrl,
                    enabled: !ordenCreada,
                    decoration: const InputDecoration(
                      labelText: 'Código Postal',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    enabled: !ordenCreada,
                    decoration: const InputDecoration(
                      labelText: 'Referencias de entrega (opcional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.cardSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Total a pagar: \$${widget.cart.estimatedTotal.toStringAsFixed(2)} MXN',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkNavy,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!ordenCreada)
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed:
                                    _processing ? null : _iniciarOrdenPayPal,
                                icon: const Icon(Icons.account_balance_wallet),
                                label: Text(
                                  _processing
                                      ? 'Conectando con PayPal...'
                                      : 'Pagar con PayPal Sandbox',
                                ),
                              ),
                            )
                          else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.parchment,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.warmBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Orden PayPal: $_paypalOrderId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '1. Inicia sesión con tu cuenta comprador Sandbox en la pestaña abierta de PayPal y aprueba el pago.\n'
                                    '2. Regresa aquí y pulsa "Confirmar pago aprobado".',
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                  if (_approveUrl != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _abrirVentanaPayPal(_approveUrl!),
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Volver a abrir ventana de PayPal',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed:
                                    _processing ? null : _capturarPagoPayPal,
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _processing
                                      ? 'Capturando pago...'
                                      : 'Confirmar pago aprobado',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Nota: Una vez completada tu compra, podrás descargar tu factura en formato PDF desde tu perfil en la aplicación web.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
