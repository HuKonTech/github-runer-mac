#!/usr/bin/env bash
# Build and run script for Linux and macOS

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$REPO_ROOT/.venv"

cd "$REPO_ROOT"

# ── Find Python 3.11+ ────────────────────────────────────────────────────────
find_python() {
    for candidate in "${PYTHON:-}" python3.13 python3.12 python3.11; do
        [ -z "$candidate" ] && continue
        if command -v "$candidate" &>/dev/null; then
            local major minor
            major=$("$candidate" -c "import sys; print(sys.version_info.major)")
            minor=$("$candidate" -c "import sys; print(sys.version_info.minor)")
            if [ "$major" -eq 3 ] && [ "$minor" -ge 11 ]; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

echo "==> Checking Python..."
if ! PYTHON=$(find_python); then
    echo "ERROR: Python 3.11+ not found." >&2
    echo "       Install it from https://www.python.org/downloads/ and retry." >&2
    exit 1
fi

EXPECTED_VER=$("$PYTHON" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "    Using Python $EXPECTED_VER ($PYTHON)"

# ── libedgetpu system driver ─────────────────────────────────────────────────
install_libedgetpu_macos() {
    # Check if already installed (dylib present in a known path)
    if ls /usr/local/lib/libedgetpu* /opt/homebrew/lib/libedgetpu* 2>/dev/null | grep -q libedgetpu; then
        echo "    libedgetpu already installed."
        return 0
    fi

    if ! system_profiler SPUSBDataType 2>/dev/null | grep -q "Global Unichip\|Coral\|1a6e\|18d1"; then
        echo "    No Coral USB device detected — skipping libedgetpu install."
        return 0
    fi

    echo "    Downloading libedgetpu runtime from GitHub..."
    local ZIP_URL="https://github.com/google-coral/libedgetpu/releases/download/release-grouper/edgetpu_runtime_20221024.zip"
    local TMP_ZIP="/tmp/edgetpu_rt.zip"
    local TMP_DIR="/tmp/edgetpu_rt"

    if command -v curl &>/dev/null; then
        curl -fsSL "$ZIP_URL" -o "$TMP_ZIP" || { echo "    WARNING: Download failed." >&2; return 1; }
    else
        echo "    WARNING: curl not found — install libedgetpu manually:" >&2
        echo "    $ZIP_URL" >&2
        return 1
    fi

    unzip -qo "$TMP_ZIP" -d "$TMP_DIR" || { echo "    WARNING: unzip failed." >&2; return 1; }

    echo "    Running install.sh (requires sudo)..."
    if sudo bash "$TMP_DIR/edgetpu_runtime/install.sh"; then
        echo "    libedgetpu installed successfully."
    else
        echo ""
        echo "    WARNING: Automatic install failed (sudo required)."
        echo "    Run these commands manually in Terminal:"
        echo "      curl -fsSL \"$ZIP_URL\" -o /tmp/edgetpu_rt.zip"
        echo "      unzip -qo /tmp/edgetpu_rt.zip -d /tmp/edgetpu_rt"
        echo "      sudo bash /tmp/edgetpu_rt/edgetpu_runtime/install.sh"
        echo ""
    fi
}

install_libedgetpu_linux() {
    if ldconfig -p 2>/dev/null | grep -q "libedgetpu"; then
        echo "    libedgetpu already installed."
        return 0
    fi
    echo "    Installing libedgetpu..."
    if ! command -v apt-get &>/dev/null; then
        echo "    WARNING: apt-get not found. Install libedgetpu manually:" >&2
        echo "             https://coral.ai/software/#debian-packages" >&2
        return 1
    fi
    echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" \
        | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list > /dev/null
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo apt-key add - > /dev/null 2>&1
    sudo apt-get update -qq
    sudo apt-get install -y libedgetpu1-std
}

echo "==> Checking Coral Edge TPU driver (libedgetpu)..."
OS="$(uname -s)"
case "$OS" in
    Darwin) install_libedgetpu_macos ;;
    Linux)  install_libedgetpu_linux ;;
    *)      echo "    Unsupported OS '$OS' — skipping libedgetpu check." ;;
esac

# ── Virtual environment ───────────────────────────────────────────────────────
echo "==> Setting up virtual environment at $VENV_DIR ..."

if [ -f "$VENV_DIR/bin/python" ]; then
    VENV_VER=$("$VENV_DIR/bin/python" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
    if [ "$VENV_VER" != "$EXPECTED_VER" ]; then
        echo "    Stale venv (Python $VENV_VER) — removing and rebuilding with $EXPECTED_VER..."
        rm -rf "$VENV_DIR"
    fi
fi

if [ ! -f "$VENV_DIR/bin/python" ]; then
    "$PYTHON" -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# ── Python dependencies ───────────────────────────────────────────────────────
echo "==> Installing / updating dependencies..."
pip install --upgrade pip setuptools wheel --quiet
pip install -e ".[dev]" --quiet

echo "==> Trying optional TPU packages (ai-edge-litert + pycoral)..."
if pip install -e ".[tflite]" --quiet 2>/dev/null; then
    echo "    TPU support enabled."
else
    echo "    WARNING: ai-edge-litert or pycoral not available for Python $EXPECTED_VER."
    echo "    Coral/TPU features will be disabled at runtime."
    echo "    See: https://coral.ai/software/#pycoral-api"
fi

# ── Download model files ──────────────────────────────────────────────────────
echo "==> Checking model files..."
MODELS_DIR="$REPO_ROOT/models"
mkdir -p "$MODELS_DIR"

download_if_missing() {
    local dest="$1" url="$2" label="$3"
    if [ -f "$dest" ]; then
        echo "    [ok] $label"
        return 0
    fi
    echo "    Downloading $label ..."
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest" || { echo "    WARNING: Failed to download $label" >&2; return 1; }
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$dest" || { echo "    WARNING: Failed to download $label" >&2; return 1; }
    else
        echo "    WARNING: curl/wget not found — cannot download $label" >&2
        return 1
    fi
    echo "    [ok] $label downloaded"
}

# Caffe SSD CPU face detector (OpenCV res10)
download_if_missing \
    "$MODELS_DIR/deploy.prototxt" \
    "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/deploy.prototxt" \
    "deploy.prototxt (CPU detector)"

download_if_missing \
    "$MODELS_DIR/res10_300x300_ssd_iter_140000.caffemodel" \
    "https://raw.githubusercontent.com/opencv/opencv_3rdparty/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000.caffemodel" \
    "res10_300x300_ssd_iter_140000.caffemodel (CPU detector)"

# Coral Edge TPU face detection model
download_if_missing \
    "$MODELS_DIR/ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite" \
    "https://raw.githubusercontent.com/google-coral/test_data/master/ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite" \
    "ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite (Coral detector)"

# MobileFaceNet embedding model — try several known-working mirrors
FACENET="$MODELS_DIR/mobilefacenet.tflite"

validate_facenet() {
    local path="$1"
    python3 - "$path" <<'PY' 2>/dev/null
import sys
path = sys.argv[1]
try:
    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError:
        from tensorflow.lite import Interpreter  # type: ignore[import]
    interp = Interpreter(model_path=path)
    interp.allocate_tensors()
    inp = interp.get_input_details()
    out = interp.get_output_details()
    in_shape = inp[0]["shape"].tolist() if inp else []
    out_shape = out[0]["shape"].tolist() if out else []
    ok_in  = len(in_shape)  == 4 and in_shape[1]  in (112, 160) and in_shape[3] == 3
    ok_out = len(out_shape) == 2 and out_shape[0] == 1 and out_shape[1] in (128, 192, 512)
    print("ok" if (ok_in and ok_out) else f"bad:{in_shape}->{out_shape}")
except Exception as exc:
    print(f"err:{exc}")
PY
}

if [ -f "$FACENET" ]; then
    RESULT=$(validate_facenet "$FACENET")
    if [ "$RESULT" != "ok" ]; then
        echo "    Removing incompatible mobilefacenet.tflite ($RESULT)..."
        rm -f "$FACENET"
    else
        echo "    [ok] mobilefacenet.tflite (validated)"
    fi
fi

if [ ! -f "$FACENET" ]; then
    echo "    Downloading MobileFaceNet embedding model (trying mirrors)..."
    MFN_URLS=(
        "https://github.com/shubham0204/FaceRecognition_With_FaceNet_Android/raw/master/app/src/main/assets/mobile_face_net.tflite"
        "https://github.com/estebanuri/face_recognition/raw/master/android/face-recognition/app/src/main/assets/mobile_face_net.tflite"
        "https://github.com/Martlgap/FaceIDLight/raw/main/facelib/models/pretrained/mobileFaceNet.tflite"
    )
    for url in "${MFN_URLS[@]}"; do
        echo "    → $url"
        if curl -fsSL "$url" -o "$FACENET.tmp" 2>/dev/null; then
            mv "$FACENET.tmp" "$FACENET"
            RESULT=$(validate_facenet "$FACENET")
            if [ "$RESULT" = "ok" ]; then
                echo "    [ok] mobilefacenet.tflite downloaded and validated"
                break
            else
                echo "    [skip] downloaded file invalid ($RESULT)"
                rm -f "$FACENET"
            fi
        else
            rm -f "$FACENET.tmp"
        fi
    done
fi

if [ ! -f "$FACENET" ]; then
    echo "    MobileFaceNet unavailable — SFace (OpenCV) will be used instead."
fi

# SFace recognition model — used when MobileFaceNet is absent
download_if_missing \
    "$MODELS_DIR/sface.onnx" \
    "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx" \
    "sface.onnx (face recognition, 37 MB)"

# ── Auto-generate config.yaml if missing ─────────────────────────────────────
CONFIG="$REPO_ROOT/config.yaml"
if [ ! -f "$CONFIG" ]; then
    echo "==> Generating config.yaml ..."
    cat > "$CONFIG" <<'YAML'
# Auto-generated by build_and_run.sh — edit as needed.

detection:
  confidence_threshold: 0.65
  min_face_size: 50
  # Coral Edge TPU model — comment out to force CPU-only mode
  coral_model_path: models/ssd_mobilenet_v2_face_quant_postprocess_edgetpu.tflite
  # CPU DNN fallback model (OpenCV Caffe SSD)
  cpu_model_path: models/res10_300x300_ssd_iter_140000.caffemodel

embedding:
  # Place mobilefacenet.tflite in models/ for production-quality grouping
  model_path: models/mobilefacenet.tflite
  input_size: [112, 112]
  embedding_dim: 192

clustering:
  epsilon: 0.4
  min_samples: 2
  metric: cosine

storage:
  db_path: data/faces.db
  crops_dir: data/crops

scan:
  image_extensions: [.jpg, .jpeg, .png, .webp]
  worker_threads: 2
  thumbnail_size: [128, 128]
YAML
    echo "    [ok] config.yaml created"
else
    echo "==> config.yaml already exists — skipping generation"
fi

echo "==> Build complete. Launching application..."
exec python -m app.main "$@"
