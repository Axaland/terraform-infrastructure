import 'package:flutter/material.dart';

class ProviderLoginButton extends StatelessWidget {
  const ProviderLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final String provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == 'apple';
    final icon = isApple ? Icons.apple : Icons.login;
    final label = isApple ? 'Continua con Apple' : 'Continua con Google';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: Icon(icon),
        onPressed: onPressed,
        label: Text(label),
      ),
    );
  }
}
