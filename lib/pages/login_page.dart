import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_palette.dart';
import '../widgets/app_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.state, super.key});
  final AppState state;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final captcha = TextEditingController();
  final sms = TextEditingController();
  final otp = List.generate(6, (_) => TextEditingController());
  final otpFocus = List.generate(6, (_) => FocusNode());
  final token = TextEditingController();
  late String seed;
  late String captchaUrl;
  bool tokenMode = false;
  bool codeStep = false;
  Timer? _resendTimer;
  int _remainingSeconds = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    phone.dispose();
    captcha.dispose();
    sms.dispose();
    token.dispose();
    for (final item in otp) {
      item.dispose();
    }
    for (final item in otpFocus) {
      item.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {
    seed = '${_randomString()}${_randomString()}';
    captchaUrl = widget.state.api.captchaUrl(seed);
  });

  String _randomString() {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      12,
      (_) => characters[Random().nextInt(characters.length)],
    ).join();
  }

  Future<void> _send() async {
    if (!RegExp(r'^\d{11}$').hasMatch(phone.text)) {
      setState(() => error = '请输入正确的手机号');
      return;
    }
    final r = await widget.state.sendSmsCode(phone.text, captcha.text, seed);
    if (!mounted) return;
    setState(() {
      error = r;
      codeStep = r == null;
    });
    if (r == null) _startResendCountdown();
    if (r != null) _refresh();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<void> _loginSms() async {
    sms.text = otp.map((item) => item.text).join();
    final r = await widget.state.loginBySms(phone.text, sms.text);
    if (mounted && r != null) setState(() => error = r);
  }

  Future<void> _loginCredentials() async {
    final result = await widget.state.loginWithCredentials(token.text);
    if (mounted) setState(() => error = result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(widget.state.dark);
    return AppPage(
      dark: widget.state.dark,
      children: [
        const SizedBox(height: 40),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.tint,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset('lib/static/logo.png'),
          ),
        ),
        const SizedBox(height: 24),
        const AppHeader(title: '奶娃喝水', subtitle: '给日常补水，也给自己一点元气'),
        AppSurface(
          dark: widget.state.dark,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tokenMode
                    ? '密钥登录'
                    : codeStep
                    ? '输入验证码'
                    : '欢迎回来',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                tokenMode
                    ? '粘贴完整密钥，快速回到你的账户'
                    : codeStep
                    ? '验证码已发送至 ${phone.text}'
                    : '登录后，开始你的第一杯水',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              if (tokenMode) ...[
                _tokenInput(),
                const SizedBox(height: 22),
                _button(
                  '登录',
                  widget.state.authLoading ? null : _loginCredentials,
                ),
              ] else if (codeStep) ...[
                _otpInput(),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _remainingSeconds > 0 || widget.state.authLoading
                      ? null
                      : _openCaptcha,
                  child: Text(
                    _remainingSeconds > 0
                        ? '重新发送（$_remainingSeconds）'
                        : '重新发送验证码',
                  ),
                ),
                const SizedBox(height: 12),
                _button('下一步', widget.state.authLoading ? null : _loginSms),
              ] else ...[
                _phoneInput(),
                const SizedBox(height: 22),
                _button(
                  '获取短信验证码',
                  widget.state.authLoading ? null : _openCaptcha,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: colors.danger,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Tooltip(
          message: tokenMode ? '使用手机号登录' : '使用登录凭证',
          child: TextButton.icon(
            onPressed: widget.state.authLoading
                ? null
                : () => setState(() {
                    tokenMode = !tokenMode;
                    codeStep = false;
                    error = null;
                  }),
            icon: Icon(
              tokenMode ? Icons.phone_android_rounded : Icons.key_outlined,
              size: 18,
            ),
            label: Text(tokenMode ? '使用手机号登录' : '使用登录凭证'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: colors.muted, size: 13),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '登录密钥安全保存在当前设备',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openCaptcha() async {
    if (!RegExp(r'^\d{11}$').hasMatch(phone.text)) {
      setState(() => error = '请输入正确的手机号');
      return;
    }
    captcha.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '安全验证',
                  style: TextStyle(
                    color: Color(0xff192745),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '请输入图形验证码后获取短信验证码',
                  style: TextStyle(color: Color(0xff65728f)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _input(captcha, '图形验证码')),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _refresh,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          captchaUrl,
                          key: ValueKey(captchaUrl),
                          width: 108,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              '加载失败',
                              style: TextStyle(
                                color: Color(0xff65728f),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _button('确认并获取', () async {
                  Navigator.pop(dialogContext);
                  await _send();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneInput() => TextField(
    controller: phone,
    keyboardType: TextInputType.phone,
    autofillHints: const [AutofillHints.telephoneNumberNational],
    style: Theme.of(context).textTheme.bodyLarge,
    decoration: const InputDecoration(
      hintText: '手机号',
      prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
      prefixText: '+86  ',
    ),
  );

  Widget _otpInput() => Row(
    children: List.generate(
      6,
      (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 5 ? 0 : 6),
          child: TextField(
            controller: otp[index],
            focusNode: otpFocus[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              color: AppColors(widget.state.dark).ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors(widget.state.dark).border,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                otpFocus[index + 1].requestFocus();
              }
            },
          ),
        ),
      ),
    ),
  );

  Widget _input(TextEditingController controller, String hint) => TextField(
    controller: controller,
    decoration: InputDecoration(hintText: hint),
  );

  Widget _tokenInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('798 登录密钥', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 10),
      TextField(
        controller: token,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          hintText: '粘贴完整登录密钥（含 token 和 UID）',
          prefixIcon: Icon(Icons.key_outlined, size: 20),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '在“我的”中点击账户卡片复制密钥，在这里粘贴一行即可登录。',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _button(String text, VoidCallback? action) => ElevatedButton(
    onPressed: action,
    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
    child: widget.state.authLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text(text),
  );
}
