"""SFace face embedder via cv2.FaceRecognizerSF.

Uses OpenCV's built-in SFace model — no extra Python packages needed beyond
opencv-python.  Model file must be downloaded separately (~37 MB).

Download:
    scripts/build_and_run.sh fetches this automatically, or manually:
    curl -L https://github.com/opencv/opencv_zoo/raw/main/models/\
face_recognition_sface/face_recognition_sface_2021dec.onnx \
         -o models/sface.onnx

Embeddings:
    128-dimensional, L2-normalised.  Suitable for cosine-distance clustering.
"""

from __future__ import annotations

import logging
from pathlib import Path

import cv2
import numpy as np

from app.embeddings.base import FaceEmbedder
from app.paths import resource_path

log = logging.getLogger(__name__)


def _is_grayscale(img_bgr: np.ndarray, threshold: float = 8.0) -> bool:
    """Return True if the image channels are nearly identical (B&W scan/photo)."""
    b, g, r = cv2.split(img_bgr.astype(np.int16))
    return (
        float(np.std(r - g)) < threshold
        and float(np.std(g - b)) < threshold
    )


def _enhance_grayscale(img_bgr: np.ndarray) -> np.ndarray:
    """Apply CLAHE contrast enhancement on grayscale images.

    Converts to single-channel, runs CLAHE, then returns a 3-channel BGR image
    so downstream models receive the expected shape.
    """
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    return cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR)

_DEFAULT_MODEL_PATH = "models/sface.onnx"
_INPUT_SIZE = (112, 112)
_EMBED_DIM = 128


class SFaceEmbedder(FaceEmbedder):
    """Face embedder backed by cv2.FaceRecognizerSF (SFace model)."""

    def __init__(self, model_path: str | None = None) -> None:
        resolved = Path(model_path) if model_path else resource_path(_DEFAULT_MODEL_PATH)
        if not resolved.exists():
            raise FileNotFoundError(f"SFace model not found: {resolved}")
        self._recognizer = cv2.FaceRecognizerSF.create(str(resolved), "")
        self._backend = "sface"
        log.info("SFace embedder loaded: %s", resolved.name)

    @property
    def embedding_dim(self) -> int:
        return _EMBED_DIM

    def embed(self, face_bgr: np.ndarray) -> np.ndarray:
        if _is_grayscale(face_bgr):
            face_bgr = _enhance_grayscale(face_bgr)
        resized = cv2.resize(face_bgr, _INPUT_SIZE, interpolation=cv2.INTER_LINEAR)
        feat = self._recognizer.feature(resized)
        vec = feat.flatten().astype(np.float32)
        norm = np.linalg.norm(vec)
        return vec if norm < 1e-8 else vec / norm
