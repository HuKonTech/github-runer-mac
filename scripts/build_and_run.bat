@echo off
:: Build and run script for Windows

setlocal EnableDelayedExpansion

set "REPO_ROOT=%~dp0.."
set "VENV_DIR=%REPO_ROOT%\.venv"
set "MODELS_DIR=%REPO_ROOT%\models"

pushd "%REPO_ROOT%"

:: ── Find Python 3.11+ ────────────────────────────────────────────────────────
echo =^> Checking Python...
set "PYTHON="

for %%c in (python3.13 python3.12 python3.11 python3 python) do (
    if not defined PYTHON (
        where %%c >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=*" %%v in ('%%c -c "import sys; ok = sys.version_info >= (3,11); print('ok' if ok else 'old')" 2^>nul') do (
                if "%%v"=="ok" set "PYTHON=%%c"
            )
        )
    )
)

if not defined PYTHON (
    echo ERROR: Python 3.11+ not found.
    echo        Install it from https://www.python.org/downloads/ and add it to PATH.
    exit /b 1
)

for /f "tokens=*" %%v in ('%PYTHON% -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"') do set PY_VER=%%v
echo     Using Python %PY_VER% ^(%PYTHON%^)

:: ── Virtual environment ───────────────────────────────────────────────────────
echo =^> Setting up virtual environment at %VENV_DIR% ...
if exist "%VENV_DIR%\Scripts\python.exe" (
    for /f "tokens=*" %%v in ('"%VENV_DIR%\Scripts\python.exe" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2^>nul') do set VENV_VER=%%v
    if not "!VENV_VER!"=="%PY_VER%" (
        echo     Stale venv ^(Python !VENV_VER!^) — rebuilding with %PY_VER%...
        rmdir /s /q "%VENV_DIR%"
    )
)
if not exist "%VENV_DIR%\Scripts\python.exe" (
    %PYTHON% -m venv "%VENV_DIR%"
)

call "%VENV_DIR%\Scripts\activate.bat"

:: ── Dependencies ──────────────────────────────────────────────────────────────
echo =^> Installing / updating dependencies...
python -m pip install --upgrade pip setuptools wheel --quiet
python -m pip install -e ".[dev]" --quiet

echo =^> Trying optional TPU packages (ai-edge-litert)...
python -m pip install -e ".[tflite]" --quiet 2>nul
if errorlevel 1 (
    echo     WARNING: TPU support unavailable for Python %PY_VER%.
)

:: ── Model downloads ──────────────────────────────────────────────────────────
echo =^> Checking model files...
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

call :download "%MODELS_DIR%\deploy.prototxt" "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/deploy.prototxt" "deploy.prototxt"
call :download "%MODELS_DIR%\res10_300x300_ssd_iter_140000.caffemodel" "https://raw.githubusercontent.com/opencv/opencv_3rdparty/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000.caffemodel" "res10 caffemodel"
call :download "%MODELS_DIR%\ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite" "https://raw.githubusercontent.com/google-coral/test_data/master/ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite" "Coral detector"

:: MobileFaceNet — try mirrors
set "FACENET=%MODELS_DIR%\mobilefacenet.tflite"
if not exist "%FACENET%" (
    echo     Downloading MobileFaceNet ^(trying mirrors^)...
    call :try_download "%FACENET%" "https://github.com/shubham0204/FaceRecognition_With_FaceNet_Android/raw/master/app/src/main/assets/mobile_face_net.tflite"
    if not exist "%FACENET%" (
        call :try_download "%FACENET%" "https://github.com/estebanuri/face_recognition/raw/master/android/face-recognition/app/src/main/assets/mobile_face_net.tflite"
    )
    if not exist "%FACENET%" (
        echo     WARNING: Could not auto-download MobileFaceNet — HOG fallback will be used.
        echo              Place mobilefacenet.tflite in models\ manually for good clustering.
    )
)

:: ── Config ────────────────────────────────────────────────────────────────────
if not exist "%REPO_ROOT%\config.yaml" (
    echo =^> Generating config.yaml ...
    (
        echo detection:
        echo   confidence_threshold: 0.65
        echo   min_face_size: 50
        echo   coral_model_path: models/ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite
        echo   cpu_model_path: models/res10_300x300_ssd_iter_140000.caffemodel
        echo.
        echo embedding:
        echo   model_path: models/mobilefacenet.tflite
        echo   input_size: [112, 112]
        echo   embedding_dim: 192
        echo.
        echo clustering:
        echo   epsilon: 0.4
        echo   min_samples: 2
        echo   metric: cosine
        echo.
        echo storage:
        echo   db_path: data/faces.db
        echo   crops_dir: data/crops
        echo.
        echo scan:
        echo   image_extensions: [.jpg, .jpeg, .png, .webp]
        echo   worker_threads: 2
        echo   thumbnail_size: [128, 128]
    ) > "%REPO_ROOT%\config.yaml"
)

echo =^> Build complete. Launching application...
python -m app.main %*

popd
endlocal
exit /b 0

:download
if exist "%~1" (
    echo     [ok] %~3
    goto :eof
)
echo     Downloading %~3 ...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%~2' -OutFile '%~1' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 echo     WARNING: Failed to download %~3
goto :eof

:try_download
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%~2' -OutFile '%~1' -UseBasicParsing } catch { exit 1 }"
goto :eof
