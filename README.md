# Woofy Flutter

Cliente móvil de Woofy preparado para Android e iOS. La Fase 0 incluye
bootstrap de Supabase, navegación global, Riverpod, tema base y componentes
compartidos. Catálogo, autenticación, favoritos y mensajes quedan fuera de
esta fase.

## Configuración local

1. Copiá `.env.example` como `.env`.
2. Configurá la URL del proyecto y su key pública de cliente:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-public-client-key
```

La key puede provenir de una publishable key actual o de una anon key legacy.
Nunca uses una secret key ni una `service_role` key dentro de Flutter. El
archivo `.env` se empaqueta en la aplicación y no debe considerarse secreto.
La seguridad de los datos depende de grants y políticas RLS en Supabase.

En CI, generá `.env` antes de ejecutar `flutter pub get` o construir la app.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Para validar Android con el emulador existente:

```bash
flutter emulators --launch Pixel_7
flutter devices
flutter run -d <android-device-id>
```

## Rutas de Fase 0

- `/`
- `/perros`
- `/perros/:slug`
- `/auth`

Las rutas muestran placeholders deliberados. No contienen datos simulados ni
lógica de producto de fases posteriores.

## Compatibilidad iOS

La estructura y los paquetes mantienen compatibilidad con iOS. La
configuración avanzada de Keychain para `flutter_secure_storage` se validará
cuando el servicio se utilice y se ejecute una compilación iOS específica.
