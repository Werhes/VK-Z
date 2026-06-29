@echo off
chcp 65001 >nul
title VK-Z Android Universal APK Builder

:: Переходим в папку со скриптом
cd /d "%~dp0"

echo ============================================
echo    VK-Z - Сборка Universal APK
echo ============================================
echo.

:: Проверка наличия Java
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ОШИБКА] Java не найдена! Установите JDK 17+.
    echo.
    pause
    exit /b 1
)

:: Проверка версии Java (нужна 17+)
java -version 2>&1 | findstr /i "version" > "%TEMP%\java_ver.txt"
set /p JAVA_VERSION=<"%TEMP%\java_ver.txt"
del "%TEMP%\java_ver.txt"
echo [OK] Java: %JAVA_VERSION%

:: Проверка что Java 17+
echo %JAVA_VERSION% | findstr /r "\"1\.[0-9]\."" >nul
if %ERRORLEVEL% equ 0 (
    echo [ОШИБКА] Требуется Java 17 или выше! Установлена старая версия.
    echo.
    echo Установите JDK 17+ и настройте JAVA_HOME:
    echo   https://adoptium.net/temurin/releases/?version=17
    echo.
    pause
    exit /b 1
)

:: Проверка JAVA_HOME
if "%JAVA_HOME%"=="" (
    echo [ПРЕДУПРЕЖДЕНИЕ] JAVA_HOME не задан. Пробуем найти JDK...
    where javac >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [ОШИБКА] javac не найден! Установите JDK 17+.
        pause
        exit /b 1
    )
)

:: Проверка наличия ANDROID_HOME
if "%ANDROID_HOME%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
    ) else (
        echo [ОШИБКА] ANDROID_HOME не задан!
        echo Укажите путь к Android SDK в переменной окружения ANDROID_HOME
        echo.
        pause
        exit /b 1
    )
)
echo [OK] Android SDK: %ANDROID_HOME%

:: Создание local.properties если нет
if not exist "local.properties" (
    echo sdk.dir=%ANDROID_HOME:\=\\> "local.properties"
    echo [OK] Создан local.properties
)

:: Проверка gradlew
if not exist "gradlew" (
    echo [ОШИБКА] gradlew не найден!
    pause
    exit /b 1
)

echo.
echo [1/3] Очистка предыдущей сборки...
echo Запуск: gradlew clean --no-daemon
echo.
powershell -Command ".\gradlew clean --no-daemon 2>&1; exit $LASTEXITCODE" > gradle_output.txt
set BUILD_RESULT=%ERRORLEVEL%
type gradle_output.txt
if %BUILD_RESULT% neq 0 (
    echo.
    echo [ОШИБКА] Очистка не удалась! Код ошибки: %BUILD_RESULT%
    del gradle_output.txt 2>nul
    pause
    exit /b 1
)
del gradle_output.txt 2>nul
echo [OK] Очистка завершена

echo.
echo [2/3] Сборка Universal APK (Debug)...
echo Запуск: gradlew assembleDebug --no-daemon
echo.
powershell -Command ".\gradlew assembleDebug --no-daemon 2>&1; exit $LASTEXITCODE" > gradle_output.txt
set BUILD_RESULT=%ERRORLEVEL%
type gradle_output.txt
if %BUILD_RESULT% neq 0 (
    echo.
    echo [ОШИБКА] Сборка не удалась! Код ошибки: %BUILD_RESULT%
    echo.
    echo Проверьте вывод выше для поиска причины.
    del gradle_output.txt 2>nul
    pause
    exit /b 1
)
del gradle_output.txt 2>nul
echo [OK] Сборка завершена

:: Поиск APK
echo.
echo [3/3] Поиск собранного APK...
set APK_FILE=
for /r "app\build\outputs" %%f in (*.apk) do set APK_FILE=%%f

if not "%APK_FILE%"=="" (
    copy /Y "%APK_FILE%" "VK-Z-Universal.apk" >nul
    echo [OK] Universal APK создан: VK-Z-Universal.apk
    for %%f in ("%APK_FILE%") do echo [INFO] Размер: %%~zf байт
) else (
    echo [ПРЕДУПРЕЖДЕНИЕ] APK не найден!
    echo.
    echo Проверьте папку app\build\outputs\ вручную.
)

echo.
echo ============================================
echo    Сборка завершена!
echo ============================================
echo.
pause