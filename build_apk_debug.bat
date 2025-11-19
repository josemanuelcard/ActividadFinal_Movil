@echo off
echo Limpiando build anterior...
flutter clean

echo Obteniendo dependencias...
flutter pub get

echo Construyendo APK de DEBUG (para pruebas)...
flutter build apk --debug

echo.
echo ========================================
echo APK de DEBUG generado exitosamente!
echo Ubicacion: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Este APK es para PRUEBAS y no requiere firma.
echo ========================================
pause

