# Woofy

Cliente móvil de Woofy para Android e iOS: catálogo de perros en adopción,
postulaciones, mensajería entre adoptantes y refugios, y portal para que los
refugios publiquen.

Comparte backend (Supabase) con el sitio web, que vive en el repo hermano
`woofy-adopci-n-responsable`. **El esquema SQL y las Edge Functions se versionan
allá**, en `supabase/migrations/` y `supabase/functions/`.

## Puesta en marcha

```bash
cp .env.example .env     # obligatorio: sin .env la app no arranca
flutter pub get
flutter run
```

`.env` se empaqueta como asset (`pubspec.yaml`) y se carga en el arranque
(`lib/main.dart`). Está gitignoreado, así que un clone limpio no compila hasta
copiarlo. En CI hay que generarlo antes de `flutter pub get`.

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-public-client-key
AUTH_EMAIL_REDIRECT_TO=https://.../auth/confirmed
```

La key es pública: viaja dentro del binario y no debe considerarse secreta.
Nunca uses una `service_role`. La seguridad depende de las políticas RLS.

**JDK para Android.** Se configura por desarrollador, fuera del repo:

```bash
flutter config --jdk-dir="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

## Comandos

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --no-codesign
```

## Arquitectura

```
lib/
  app/        router, shell de navegación, arranque
  core/       config, errores, theme, servicios (Supabase, secure storage)
  features/   una carpeta por dominio
  shared/     widgets del design system (WoofyButton, WoofyCard, …)
```

Cada feature sigue el mismo patrón: `data/` con modelos y un repositorio
—interfaz abstracta + implementación Supabase + fuente de datos inyectable, que
es lo que hace testeable todo sin red—, `providers/` con Riverpod, y
`presentation/` con páginas y widgets.

Features: `landing`, `dogs`, `favorites`, `applications`, `messages`, `auth`,
`publisher`, `reports`, `blocks`, `legal`.

## Autenticación

Conviven **dos mecanismos distintos**, y esto condiciona cualquier regla de
acceso que agregues:

- **Adoptantes** → Supabase Auth (email, Google, Apple). El acceso a datos pasa
  por RLS con `auth.uid()`.
- **Refugios** → portal propio, con `session_id` + `token` contra RPCs
  `shelter_portal_*`. **No hay `auth.uid()`**, así que las RPCs son
  `SECURITY DEFINER` y validan a mano. La sesión se guarda en secure storage.

Consecuencia práctica: una regla implementada solo en RLS deja pasar al portal
de refugios, y viceversa. Siempre las dos vías.

El ingreso acepta email o nombre de usuario; si no hay `@`, se resuelve por el
RPC `lookup_email_by_username`.

**Deep links.** `io.woofy.app://login-callback` cierra el OAuth de Google y la
recuperación de contraseña. Que el esquema no coincida con el bundle id
(`com.woofy.app`) es intencional: está registrado así en el AndroidManifest y en
las Redirect URLs de Supabase.

Sign in with Apple usa la hoja nativa del sistema y solo se ofrece en iOS, que es
donde Apple lo exige. Al eliminar una cuenta creada con Apple hay que revocar sus
tokens: la app pide un código fresco y la Edge Function `delete-account` lo canjea
y revoca antes de borrar.

## Rutas

| Ruta | Pantalla |
|---|---|
| `/` | Portada |
| `/perros`, `/perros/:slug` | Catálogo y detalle |
| `/perros/:slug/postular` | Formulario de postulación |
| `/auth`, `/auth/recuperar`, `/auth/nueva-contrasena` | Ingreso y recuperación |
| `/perfil`, `/perfil/adoptante/editar` | Perfil del adoptante |
| `/perfil/bloqueados`, `/perfil/eliminar-cuenta` | Bloqueos y baja |
| `/favoritos` | Favoritos |
| `/mensajes`, `/mensajes/:threadId` | Mensajería |
| `/publicador`, `/publicador/nuevo`, `/publicador/:dogId/editar` | Portal de refugios |
| `/acceso-refugio`, `/perfil/refugio/editar` | Sesión y perfil del refugio |

Las tres primeras pestañas viven en un `StatefulShellRoute`; el resto son rutas
de nivel superior.

## Moderación de contenido

La App Store exige, para apps con contenido de usuarios, poder filtrar, denunciar,
bloquear y contactar al desarrollador. En la app:

- **Denunciar** perro, refugio, conversación o mensaje (este último con pulsación
  sostenida sobre la burbuja).
- **Bloquear** en ambos sentidos, con pantalla de gestión en el perfil.
- **Filtrado** por lista de términos aplicada en el servidor, más límites de
  longitud en los campos largos.
- **Contacto** accesible sin haber iniciado sesión.

Las acciones de moderación —ocultar, suspender, resolver reportes— viven en el
panel admin del sitio web.

## Build de release

Android necesita `android/key.properties` con el keystore; mirá
`android/key.properties.example`. Sin ese archivo el release firma con la debug
key y **no es publicable**, aunque el build funciona igual para que un clone
limpio compile.

## Configuración externa

Fuera del repo, en las consolas:

- **Supabase Auth** → Redirect URLs con `io.woofy.app://login-callback`;
  proveedores Google y Apple habilitados.
- **Apple Developer** → capacidad Sign in with Apple en el App ID `com.woofy.app`
  y una Key `.p8`.
- **Edge Function `delete-account`** → secretos `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
  `APPLE_CLIENT_ID` y `APPLE_PRIVATE_KEY`.
