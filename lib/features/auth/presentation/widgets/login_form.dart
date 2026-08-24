import 'package:flutter/material.dart';
import 'package:mi_app/core/utils/validators.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({required this.isLoading, required this.onSubmit, super.key});

  final bool isLoading;
  final Future<void> Function(String email, String password) onSubmit;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WoofyTextField(
            key: const ValueKey('login-email'),
            controller: _emailController,
            label: 'Email o nombre de usuario',
            validator: Validators.required,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(height: 16),
          WoofyTextField(
            key: const ValueKey('login-password'),
            controller: _passwordController,
            label: 'Contraseña',
            validator: Validators.minLength(6),
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 24),
          WoofyButton(
            label: 'Ingresar',
            onPressed: _submit,
            isLoading: widget.isLoading,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
