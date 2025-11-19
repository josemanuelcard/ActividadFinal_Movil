@echo off
echo Limpiando build anterior...
flutter clean

echo Obteniendo dependencias...
flutter pub get

echo Construyendo APK de RELEASE (para distribucion)...
flutter build apk --release

echo.
echo ========================================
echo APK de RELEASE generado exitosamente!
echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
echo.
echo NOTA: Este APK esta firmado automaticamente por Flutter
echo con una firma de debug. Para distribucion publica, necesitas
echo configurar una firma de produccion en android/app/build.gradle
echo ========================================
pause

