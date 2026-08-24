import 'package:flutter/material.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/messages/data/messages_repository.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_text_field.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.onSend,
    required this.isSending,
    super.key,
  });

  final Future<void> Function(String body) onSend;
  final bool isSending;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _submit() async {
    final body = _controller.text.trim();
    setState(() => _error = null);
    if (body.isEmpty) {
      setState(() => _error = 'Escribí un mensaje antes de enviarlo.');
      return;
    }
    if (body.length > SupabaseMessagesRepository.maxMessageLength) {
      setState(() => _error = 'El mensaje no puede superar 1.000 caracteres.');
      return;
    }
    try {
      await widget.onSend(body);
      if (!mounted) return;
      _controller.clear();
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AppException
            ? error.message
            : 'No pudimos enviar tu mensaje.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final tooLong = length > SupabaseMessagesRepository.maxMessageLength;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            WoofyTextField(
              controller: _controller,
              label: 'Mensaje',
              hint: 'Escribí un mensaje...',
              enabled: !widget.isSending,
              minLines: 1,
              maxLines: 4,
              maxLength: SupabaseMessagesRepository.maxMessageLength,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$length/1000',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tooLong
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                WoofyButton(
                  label: 'Enviar',
                  icon: Icons.send_rounded,
                  isLoading: widget.isSending,
                  onPressed: widget.isSending ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
