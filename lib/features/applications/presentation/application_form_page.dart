import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/presentation/widgets/application_form.dart';
import 'package:woofy/features/applications/presentation/widgets/application_status_card.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_celebration.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

class ApplicationFormPage extends ConsumerWidget {
  const ApplicationFormPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dogDetailProvider(slug));
    return BackFallbackScope(
      fallbackLocation: RoutePaths.dogDetail(slug),
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Postulación'),
        body: SafeArea(
          child: detail.when(
            loading: () => const WoofyLoading(message: 'Cargando formulario…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos cargar el formulario.',
              onRetry: () => ref.invalidate(dogDetailProvider(slug)),
            ),
            data: (value) => value == null
                ? const WoofyEmptyState(
                    title: 'Perrito no disponible',
                    message:
                        'Este perrito ya no está disponible para postular.',
                  )
                : _ApplicationBody(dog: value.dog),
          ),
        ),
      ),
    );
  }
}

class _ApplicationBody extends ConsumerWidget {
  const _ApplicationBody({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(currentDogApplicationProvider(dog.id));
    final submission = ref.watch(applicationSubmissionProvider(dog.id));
    final profile = ref.watch(currentProfileProvider).value;
    final completed = submission.value;

    if (completed != null) {
      return _Result(
        dog: dog,
        application: completed,
        message: 'Tu postulación fue enviada correctamente.',
      );
    }

    return existing.when(
      loading: () => const WoofyLoading(message: 'Revisando tu postulación…'),
      error: (_, _) => WoofyError(
        message: 'No pudimos revisar tu postulación.',
        onRetry: () => ref.invalidate(currentDogApplicationProvider(dog.id)),
      ),
      data: (application) {
        if (application != null) {
          return _Result(dog: dog, application: application);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Postular a ${dog.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contanos sobre tu hogar para que el refugio pueda evaluar la adopción.',
                  ),
                  const SizedBox(height: 24),
                  if (submission.hasError) ...[
                    Text(
                      submission.error is AppException
                          ? (submission.error! as AppException).message
                          : 'No pudimos enviar la postulación.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ApplicationForm(
                    initialPhone: profile?.phone,
                    isLoading: submission.isLoading,
                    onSubmit: (formData) async {
                      try {
                        await ref
                            .read(
                              applicationSubmissionProvider(dog.id).notifier,
                            )
                            .submit(dog, formData);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Result extends StatefulWidget {
  const _Result({required this.dog, required this.application, this.message});

  final Dog dog;
  final AdoptionApplication application;

  /// Solo viene con texto cuando la postulación se acaba de enviar. Volver a
  /// una postulación vieja no se celebra: ya lo celebraste una vez.
  final String? message;

  @override
  State<_Result> createState() => _ResultState();
}

class _ResultState extends State<_Result> {
  @override
  void initState() {
    super.initState();
    // El golpecito llega junto con el check. Es lo que hace que enviar se
    // sienta en la mano y no solo en la pantalla.
    if (widget.message != null) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.message case final message?) ...[
                WoofyCelebration(
                  title: '¡${dog.name} ya sabe de vos!',
                  body:
                      '$message El refugio la va a revisar y te escribe por '
                      'Mensajes cuando tenga novedades.',
                  actions: [
                    WoofyButton(
                      label: 'Ver mis mensajes',
                      onPressed: () => context.go(RoutePaths.messages),
                      icon: Icons.chat_bubble_outline,
                      isExpanded: true,
                    ),
                    WoofyButton(
                      label: 'Seguir mirando',
                      onPressed: () => context.go(RoutePaths.dogs),
                      variant: WoofyButtonVariant.secondary,
                      isExpanded: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              ApplicationStatusCard(application: widget.application),
              const SizedBox(height: 20),
              WoofyButton(
                label: 'Volver al perfil de ${dog.name}',
                onPressed: () => context.go(RoutePaths.dogDetail(dog.slug)),
                variant: WoofyButtonVariant.secondary,
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
