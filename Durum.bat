@echo off
chcp 65001 >nul
title AION 2 Turkce Yama - Durum
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Aion2TR.ps1" -Status
pause
