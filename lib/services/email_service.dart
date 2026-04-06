import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  late final SmtpServer _smtpServer;

  void _init() {
    _smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: 'raymondtawiah23@gmail.com',
      password: 'lzwfslzljcrhbjgh',
    );
  }

  Future<void> sendOtpEmail(String email, String otp) async {
    _init();
    
    final message = Message()
      ..from = const Address('raymondtawiah23@gmail.com', 'Foodie App')
      ..recipients.add(email)
      ..subject = 'Your Foodie App Verification Code'
      ..text = '''
Your verification code is: $otp

This code will expire in 10 minutes.

If you didn't request this code, please ignore this email.
'''
      ..html = '''
<h2>Foodie App Verification</h2>
<p>Your verification code is:</p>
<h1 style="color: #673AB7; letter-spacing: 4px;">$otp</h1>
<p>This code will expire in 10 minutes.</p>
<p>If you didn't request this code, please ignore this email.</p>
''';

    await send(message, _smtpServer);
  }
}
