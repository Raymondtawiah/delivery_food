import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OrderEmailService {
  static final OrderEmailService _instance = OrderEmailService._internal();
  factory OrderEmailService() => _instance;
  OrderEmailService._internal();

  late final SmtpServer _smtpServer;

  void _init() {
    _smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: 'raymondtawiah23@gmail.com',
      password: 'lzwfslzljcrhbjgh',
    );
  }

  Future<void> sendOrderConfirmation({
    required String email,
    required String name,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String orderId,
  }) async {
    _init();
    
    final itemsHtml = items.map((item) {
      final itemName = item['name'] ?? '';
      final itemPrice = item['price'] ?? 0;
      final addons = item['addons'] as List<String>? ?? [];
      final addonPrice = item['addonPrice'] ?? 0.0;
      final totalPrice = item['totalPrice'] ?? itemPrice;
      
      String addonsHtml = '';
      if (addons.isNotEmpty) {
        addonsHtml = '<p style="font-size: 12px; color: #666; margin: 4px 0 0 0;">Addons: ${addons.join(', ')} (+₵${addonPrice.toStringAsFixed(2)})</p>';
      }
      
      return '''
      <tr style="border-bottom: 1px solid #eee;">
        <td style="padding: 12px 8px;">$itemName$addonsHtml</td>
        <td style="padding: 12px 8px; text-align: right;">₵${totalPrice.toStringAsFixed(2)}</td>
      </tr>
      ''';
    }).join('');

    final message = Message()
      ..from = const Address('raymondtawiah23@gmail.com', 'Foodie App')
      ..recipients.add(email)
      ..subject = 'Order Confirmed - #${orderId.substring(0, 8)}'
      ..text = '''
Your order has been confirmed!

Order ID: ${orderId.substring(0, 8)}
Name: $name
Phone: $phone
Address: $address

Order Items:
${items.map((item) => '- ${item['name']}: ₵${item['totalPrice']}').join('\n')}

Total: ₵${totalAmount.toStringAsFixed(2)}

Thank you for ordering with Foodie!
'''
      ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; }
    .header { background: #673AB7; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .info-label { color: #666; }
    .info-value { font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    .total-row { background: #f9f9f9; font-weight: bold; font-size: 18px; }
    .footer { background: #f5f5f5; padding: 20px; text-align: center; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin: 0;">Order Confirmed!</h1>
      <p style="margin: 5px 0 0 0;">Order #${orderId.substring(0, 8)}</p>
    </div>
    <div class="content">
      <h3>Delivery Information</h3>
      <div class="info-row">
        <span class="info-label">Name:</span>
        <span class="info-value">$name</span>
      </div>
      <div class="info-row">
        <span class="info-label">Phone:</span>
        <span class="info-value">$phone</span>
      </div>
      <div class="info-row">
        <span class="info-label">Address:</span>
        <span class="info-value">$address</span>
      </div>
      
      <h3>Order Details</h3>
      <table>
        <thead>
          <tr style="background: #673AB7; color: white;">
            <th style="padding: 12px 8px; text-align: left;">Item</th>
            <th style="padding: 12px 8px; text-align: right;">Price</th>
          </tr>
        </thead>
        <tbody>
          $itemsHtml
          <tr class="total-row">
            <td style="padding: 12px 8px;">Total</td>
            <td style="padding: 12px 8px; text-align: right; color: #673AB7;">₵${totalAmount.toStringAsFixed(2)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="footer">
      <p>Thank you for ordering with Foodie!</p>
      <p>Your order will be delivered soon.</p>
    </div>
  </div>
</body>
</html>
''';

    await send(message, _smtpServer);
  }
}
