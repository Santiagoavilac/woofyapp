import 'package:flutter/material.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/theme/woofy_theme.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';

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
