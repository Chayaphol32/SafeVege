@echo off
title SafeVege PHP API Server (Port 8081)
echo ====================================================
echo  SafeVege Backend REST API Server (Port 8081)
echo ====================================================
echo.
cd /d "%~dp0bn"
echo Current directory: %CD%
echo Starting PHP server on http://127.0.0.1:8081 ...
echo Press Ctrl+C to stop the server.
echo.
"C:\MAMP\bin\php\php8.3.1\php.exe" -c "C:\MAMP\conf\php8.3.1\php.ini" -S 127.0.0.1:8081 -t .\public .\public\index.php
pause
