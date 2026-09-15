import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: widget.state.dark
          ? Colors.black
          : const Color(0xfff6f8ff),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0, 0.34, 0.58, 1],
              colors: widget.state.dark
                  ? const [
                      Colors.black,
                      Colors.black,
                      Colors.black,
                      Colors.black,
                    ]
                  : const [
                      Color(0xff9fe1e3),
                      Color(0xffd9eeeb),
                      Color(0xfff2d8cc),
                      Color(0xfff7f8fa),
                    ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
              child: Align(
                alignment: tablet ? Alignment.topCenter : Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            '奶娃喝水',
                            style: TextStyle(
                              color: widget.state.dark
                                  ? Colors.white
                                  : const Color(0xff192745),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tokenMode
                            ? '使用登录凭证快速登录'
                            : codeStep
                            ? '验证码已发送至 ${phone.text}'
                            : '净水设备管理',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: widget.state.dark
                              ? const Color(0xffd5d5d5)
                              : const Color(0xff65728f),
                        ),
                      ),
                      const SizedBox(height: 72),
                      if (tokenMode) ...[
                        _tokenInput(),
                        const SizedBox(height: 14),
                        _button(
                          '登录',
                          widget.state.authLoading
                              ? null
                              : () => widget.state.login(token.text),
                        ),
                      ] else if (codeStep) ...[
                        Text(
                          '输入短信验证码',
                          style: const TextStyle(
                            color: Color(0xff192745),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '已向您的手机 ${phone.text.length >= 4 ? phone.text.substring(phone.text.length - 4) : phone.text} 发送验证码',
                          style: const TextStyle(
                            color: Color(0xff65728f),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 54),
                        _otpInput(),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed:
                              _remainingSeconds > 0 || widget.state.authLoading
                              ? null
                              : _openCaptcha,
                          child: Text(
                            _remainingSeconds > 0
                                ? '重新发送（$_remainingSeconds）'
                                : '重新发送验证码',
                            style: TextStyle(
                              color: _remainingSeconds > 0
                                  ? const Color(0xff737e93)
                                  : const Color(0xff536ee8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        _button(
                          '下一步',
                          widget.state.authLoading ? null : _loginSms,
                        ),
                      ] else ...[
                        _phoneInput(),
                        const SizedBox(height: 28),
                        _button(
                          '\u83b7\u53d6\u77ed\u4fe1\u9a8c\u8bc1\u7801',
                          widget.state.authLoading ? null : _openCaptcha,
                        ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xffff8b9a)),
                          ),
                        ),
                      const SizedBox(height: 54),
                      Align(
                        alignment: Alignment.center,
                        child: Material(
                          color: const Color(0x66ffffff),
                          shape: const CircleBorder(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              tooltip: tokenMode ? '使用手机号登录' : '使用登录凭证',
                              onPressed: () => setState(() {
                                tokenMode = !tokenMode;
                                codeStep = false;
                                error = null;
                              }),
                              icon: Icon(
                                tokenMode
                                    ? Icons.phone_android_rounded
                                    : Icons.key_rounded,
                                color: const Color(0xff536ee8),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

  Widget _phoneInput() => Row(
    children: [
      const Text(
        '+86',
        style: TextStyle(color: Color(0xff354463), fontSize: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Color(0xff192745), fontSize: 24),
          decoration: const InputDecoration(
            hintText: '手机号',
            hintStyle: TextStyle(color: Color(0xff8390aa)),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xffcdd6e8)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xffcdd6e8)),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _otpInput() => Row(
    children: List.generate(
      6,
      (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 5 ? 0 : 10),
          child: TextField(
            controller: otp[index],
            focusNode: otpFocus[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              color: Color(0xff192745),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xffcdd6e8)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xff7188ff), width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5)
                otpFocus[index + 1].requestFocus();
            },
          ),
        ),
      ),
    ),
  );
  Widget _input(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(color: Color(0xff192745)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff8390aa)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffcdd6e8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffcdd6e8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff6378ef), width: 2),
      ),
    ),
  );
  Widget _tokenInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '798 登录凭证',
        style: TextStyle(
          color: Color(0xff354463),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 9),
      TextField(
        controller: token,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(color: Color(0xff192745), fontSize: 15),
        decoration: InputDecoration(
          hintText: '粘贴已获取的登录凭证',
          hintStyle: const TextStyle(color: Color(0xff8390aa)),
          prefixIcon: const Icon(
            Icons.key_rounded,
            color: Color(0xff6578c8),
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xddffffff),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xffd8e0ef)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xffd8e0ef)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xff6378ef), width: 2),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        '登录凭证仅保存在当前设备，用于快速登录。',
        style: TextStyle(color: Color(0xff71809d), fontSize: 12),
      ),
    ],
  );
  Widget _button(String text, VoidCallback? action) => SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff6378ef),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
