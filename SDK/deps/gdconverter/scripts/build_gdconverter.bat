@echo off
setlocal enabledelayedexpansion
REM Build a standalone single-file binary for a gdconverter script using Nuitka (Windows)
REM Usage:
REM   export_tscn_nuitka.bat [script_name]
REM Examples:
REM   export_tscn_nuitka.bat                 (builds export_tscn)
REM   export_tscn_nuitka.bat import_spatial  (builds import_spatial)
REM   export_tscn_nuitka.bat create_godot    (builds create_godot)
REM Output:
REM   ..\..\dist\<script-name-with-hyphens>.exe

set SCRIPT_DIR=%~dp0
set GD_ROOT=%SCRIPT_DIR%..
for %%I in ("%GD_ROOT%") do set GD_ROOT=%%~fI
set PROJECT_ROOT=%GD_ROOT%
for %%I in ("%PROJECT_ROOT%") do set PROJECT_ROOT=%%~fI

set SRC_DIR=%GD_ROOT%\src
set DIST_DIR=%PROJECT_ROOT%\bin

REM Determine script name (basename without .py)
set NAME=%~1
if "%NAME%"=="" set NAME=export_tscn
set ENTRY_FILE=%SRC_DIR%\gdconverter\%NAME%.py

REM Convert underscores to hyphens for output name
set OUTPUT_NAME=%NAME:_=-%

if not exist "%ENTRY_FILE%" (
  echo Error: entry file not found: %ENTRY_FILE% 1>&2
  echo Usage: export_tscn_nuitka.bat [script_name] 1>&2
  echo Examples: export_tscn, import_spatial, create_godot 1>&2
  exit /b 1
)

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

set PYTHON_BIN=python

REM Ensure Nuitka is installed
%PYTHON_BIN% -m pip install --upgrade pip >nul 2>nul
%PYTHON_BIN% -m pip show nuitka >nul 2>nul || %PYTHON_BIN% -m pip install nuitka >nul 2>nul

echo Building %NAME% -^> %DIST_DIR%\%OUTPUT_NAME%.exe

REM Build
REM Ensure src is importable during compilation
set "PYTHONPATH=%SRC_DIR%;%PYTHONPATH%"

%PYTHON_BIN% -m nuitka ^
  --onefile ^
  --assume-yes-for-downloads ^
  --output-dir="%DIST_DIR%" ^
  --lto=no ^
  --include-package=gdconverter ^
  --noinclude-numba-mode=nofollow ^
  --nofollow-import-to=pytest ^
  --remove-output ^
  --output-filename="%OUTPUT_NAME%" ^
  "%ENTRY_FILE%"

echo Built artifacts in: %DIST_DIR%
dir "%DIST_DIR%"
endlocal
