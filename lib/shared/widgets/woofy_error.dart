import 'package:flutter/material.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';

class WoofyError extends StatelessWidget {
  const WoofyError({
    required this.message,
    this.title = 'Algo salió mal',
    this.actionLabel = 'Reintentar',
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              WoofyButton(label: actionLabel, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
