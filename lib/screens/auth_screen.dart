import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import 'chat_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showOtp = false;
  String _currentOtp = '';
  String _currentPhone = '';
  int _resendTimer = 0;
  Timer? _timer;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 9) {
      _showError('شماره معتبر نیست — ۹ رقم بدون صفر وارد کنید');
      return;
    }
    setState(() {
      _currentPhone = '+93$phone';
      _currentOtp = generateOtp();
      _showOtp = true;
      _startResendTimer();
    });
    // Focus first OTP box after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 90);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _resendTimer--);
      if (_resendTimer <= 0) {
        t.cancel();
      }
    });
  }

  void _resendOtp() {
    setState(() {
      _currentOtp = generateOtp();
    });
    _startResendTimer();
    for (final c in _otpControllers) c.clear();
    _otpFocusNodes[0].requestFocus();
  }

  void _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showError('لطفاً کد ۶ رقمی را کامل وارد کنید');
      return;
    }
    if (code != _currentOtp) {
      _showError('کد وارد شده اشتباه است');
      return;
    }

    // Verified — login
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentPhone.replaceAll(RegExp(r'[^0-9]'), '');

    var user = await ApiService.getUser(uid);
    if (user == null || user.uid.isEmpty) {
      await ApiService.createOrUpdateUser(uid, _currentPhone);
      user = await ApiService.getUser(uid);
    }

    await prefs.setString('uid', uid);
    await prefs.setString('phone', _currentPhone);
    await prefs.setString('name', user?.name ?? 'کاربر هم‌گب');
    await prefs.setString('bio', user?.bio ?? '');
    await prefs.setString('photoURL', user?.photoURL ?? '');
    await prefs.setBool('logged_in', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // Gradient header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  ),
                ),
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('هم‌گب',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('ارتباط امن، سریع و هوشمند',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: _showOtp ? _buildOtpStep(theme) : _buildPhoneStep(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('شماره تلفن خود را وارد کنید',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text('کد کشور را بررسی و شماره تلفن خود را وارد کنید',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Text('🇦🇫', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 6),
                  Text('+93',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '--- --- ---',
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Text('همگام‌سازی مخاطبین',
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.onSurfaceVariant))),
            StatefulBuilder(builder: (_, setS) {
              return Checkbox(
                value: true,
                onChanged: (v) => setS(() {}),
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _phoneController.text.trim().length == 9 ? _sendOtp : null,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('دریافت کد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Text('ورود و ادامه به معنی موافقت با حریم خصوصی و قوانین هم‌گب است',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('کد فعال‌سازی را وارد کنید',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text(_currentPhone,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        // OTP test display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('🔑 کد تست: $_currentOtp',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF856404))),
        ),
        const SizedBox(height: 20),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) => _otpBox(i, theme)),
          ),
        ),
        const SizedBox(height: 16),
        if (_resendTimer > 0)
          Center(
              child: Text('درخواست مجدد بعد از $_resendTimer ثانیه',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)))
        else
          Center(
            child: TextButton(onPressed: _resendOtp, child: const Text('ارسال مجدد کد')),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _loading ? null : _verifyOtp,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('تأیید و ورود',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _otpBox(int index, ThemeData theme) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.colorScheme.outline, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isNotEmpty && index == 5) {
            _verifyOtp();
          }
        },
      ),
    );
  }
}
