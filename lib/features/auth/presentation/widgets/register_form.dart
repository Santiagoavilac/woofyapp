import 'package:flutter/material.dart';
import 'package:mi_app/core/utils/validators.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_text_field.dart';

class RegistrationInput {
  const RegistrationInput({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String? phone;
  final String email;
  final String password;
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    required this.isLoading,
    required this.onSubmit,
    super.key,
  });

  final bool isLoading;
  final Future<void> Function(RegistrationInput input) onSubmit;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    await widget.onSubmit(
      RegistrationInput(
        fullName: _nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WoofyTextField(
            key: const ValueKey('register-name'),
            controller: _nameController,
            label: 'Nombre completo',
            validator: Validators.required,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(height: 14),
          WoofyTextField(
            key: const ValueKey('register-phone'),
            controller: _phoneController,
            label: 'Teléfono (opcional)',
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 14),
          WoofyTextField(
            key: const ValueKey('register-email'),
            controller: _emailController,
            label: 'Correo electrónico',
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 14),
          WoofyTextField(
            key: const ValueKey('register-password'),
            controller: _passwordController,
            label: 'Contraseña',
            validator: Validators.minLength(6),
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 14),
          WoofyTextField(
            key: const ValueKey('register-confirm-password'),
            controller: _confirmationController,
            label: 'Confirmar contraseña',
            validator: (value) => Validators.matches(
              _passwordController.text,
              message: 'Las contraseñas no coinciden.',
            )(value),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            prefixIcon: const Icon(Icons.lock_reset_rounded),
          ),
          const SizedBox(height: 24),
          WoofyButton(
            label: 'Crear cuenta',
            onPressed: _submit,
            isLoading: widget.isLoading,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
