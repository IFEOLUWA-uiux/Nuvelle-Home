@echo off
cd /d "%~dp0"
echo Starting Nuvelle preview server...
echo.
echo Admin: http://127.0.0.1:8789/admin.html
echo Store: http://127.0.0.1:8789/index.html
echo.
echo Keep this window open while testing in Chrome.
echo Press Ctrl+C to stop the server.
echo.
C:\Python314\python.exe -m http.server 8789 --bind 127.0.0.1
pause
