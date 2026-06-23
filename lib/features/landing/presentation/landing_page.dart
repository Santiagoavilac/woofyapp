import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/features/landing/presentation/widgets/hero_dogs_image.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_background.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_cta_section.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_header_nav.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_logo.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LandingBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: SizedBox(
                      height: compact ? null : constraints.maxHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 12 : 20,
                              compact ? 4 : 12,
                              compact ? 12 : 20,
                              0,
                            ),
                            child: LandingHeaderNav(
                              onDogsPressed: () => context.go(RoutePaths.dogs),
                              onAccountPressed: () =>
                                  context.go(RoutePaths.auth),
                            ),
                          ),
                          SizedBox(height: compact ? 4 : 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: LandingLogo(),
                          ),
                          SizedBox(height: compact ? 4 : 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: LandingCtaSection(
                              onPressed: () => context.go(RoutePaths.dogs),
                            ),
                          ),
                          SizedBox(height: compact ? 14 : 24),
                          if (!compact) const Spacer(),
                          const HeroDogsImage(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
