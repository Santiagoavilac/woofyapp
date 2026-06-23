import 'package:flutter/material.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/core/theme/woofy_theme.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({required this.exception, super.key});

  final AppException exception;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woofy',
      debugShowCheckedModeBanner: false,
      theme: WoofyTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: WoofyError(
            title: 'No pudimos iniciar Woofy',
            message: exception.message,
          ),
        ),
      ),
    );
  }
}
