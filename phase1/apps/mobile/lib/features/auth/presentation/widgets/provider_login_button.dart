import 'package:flutter/material.dart';

class ProviderLoginButton extends StatelessWidget {
  const ProviderLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final String provider;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style = _styles[provider] ?? _styles['google']!;
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isLoading ? 0.7 : 1,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foregroundColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: style.borderColor == null
                  ? BorderSide.none
                  : BorderSide(color: style.borderColor!),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        style.foregroundColor,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        style.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ButtonStyleDefinition {
  const _ButtonStyleDefinition({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
}

const Map<String, _ButtonStyleDefinition> _styles = {
  'google': _ButtonStyleDefinition(
    label: 'Continua con Google',
    icon: Icons.language,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    borderColor: Color(0xFFE0E0E0),
  ),
  'apple': _ButtonStyleDefinition(
    label: 'Continua con Apple',
    icon: Icons.apple,
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
};
