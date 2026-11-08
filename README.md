# Aromas & Memórias

Receitas (Tradicional / Airfryer / Bimby) + planeador semanal + lista de compras. Dados locais com Hive.

## Arrancar
    flutter create --project-name aromas_memorias .
    flutter pub add hive hive_flutter flutter_riverpod:^2.6.1 http path_provider share_plus:^10.1.4 file_picker:^8.1.6
    (copiar as pastas lib/ e test/ deste projeto por cima)
    flutter test
    flutter run

## Estrutura (feature-first, em camadas)
    lib/
      main.dart                 arranque (Hive + ProviderScope)
      app/                      MaterialApp e navegação principal
      core/                     tema e armazenamento (partilhado)
      features/<feature>/
        domain/                 modelos e regras (Dart puro)
        data/                   repositórios (interface + implementação Hive)
        application/            providers Riverpod (estado/lógica)
        presentation/           páginas e widgets

## Ícone e splash
    flutter pub add --dev flutter_launcher_icons flutter_native_splash
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

Imagens em `assets/icon/` e `assets/splash/`; configuração em
`flutter_launcher_icons.yaml` e `flutter_native_splash.yaml`.

## Nome por baixo do ícone
- Android: `android:label="Aromas & Memórias"` em `android/app/src/main/AndroidManifest.xml`
  (no XML escreve-se `Aromas &amp; Memórias`)
- iOS: `CFBundleDisplayName` = `Aromas & Memórias` em `ios/Runner/Info.plist`

## Importar receitas por link
Lê os dados estruturados (schema.org/Recipe) das páginas. Android: adicionar em
`android/app/src/main/AndroidManifest.xml`, acima de `<application`:

    <uses-permission android:name="android.permission.INTERNET"/>

## Backup / exportação (aba "Dados")
Exporta receitas, planeamento e lista de compras para um `.json` (partilha do
sistema: Ficheiros, Drive, e-mail…). Importar permite juntar ou substituir.
O ficheiro tem `app`, `version` e é validado por inteiro antes de escrever.

## Menu lateral (drawer)
Modo escuro/claro (guardado), Definições (aparência + backup/restauro), Feedback
(e-mail), Sobre, Sair da app (só Android) e versão.

Dependências novas:

    flutter pub add package_info_plus url_launcher
    flutter pub add flutter_localizations --sdk=flutter

No `pubspec.yaml` (secção `flutter:`) registar o logótipo:

    flutter:
      uses-material-design: true
      assets:
        - assets/branding/logo.png

Definir o e-mail de feedback em `lib/core/app_info.dart` (`feedbackEmail`).

## Fotos nas receitas
    flutter pub add image_picker

iOS: adicionar em `ios/Runner/Info.plist`:

    <key>NSCameraUsageDescription</key>
    <string>Para fotografar as suas receitas.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Para escolher fotos das suas receitas.</string>

As fotos ficam na pasta de documentos da app (`recipe_photos/`), as receitas
guardam só o nome do ficheiro, e o backup inclui as fotos (em base64).

## Se a importação por link falhar
- `flutter run` (debug) já inclui a permissão de internet; **builds de produção**
  (`flutter build apk`) só a têm se estiver em `android/app/src/main/AndroidManifest.xml`,
  como filho direto de `<manifest>`, antes de `<application>`:

      <uses-permission android:name="android.permission.INTERNET"/>

- Depois de editar o manifesto é preciso reconstruir a app (não basta hot reload).
- A mensagem de erro mostra o "Detalhe técnico" (selecionável) para diagnóstico.
