@echo off
chcp 65001 >nul
title AION 2 Turkce Yama - Geri Al
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Aion2TR.ps1" -Restore
pause
