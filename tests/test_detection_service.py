"""Unit tests for face detection service."""

from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np

from app.config import AppConfig
from app.db.database import init_db, session_scope
from app.db.models import Face, Image
from app.detectors.base import Detection, FaceDetector
from app.services.detection_service import DetectionService


class _DummyDetector(FaceDetector):
    @property
    def backend_name(self) -> str:
        return "dummy"

    def detect(
        self,
        image_bgr: np.ndarray,
        confidence_threshold: float = 0.5,
        min_face_size: int = 50,
    ):
        return [
            Detection(x=10, y=10, w=70, h=70, confidence=0.95),
            Detection(x=120, y=15, w=65, h=65, confidence=0.92),
        ]


def test_detection_service_uses_unique_face_indexes(monkeypatch, tmp_path):
    db_path = tmp_path / "faces.db"
    init_db(db_path)

    image_path = tmp_path / "family.jpg"
    img = np.full((240, 320, 3), 255, dtype=np.uint8)
    assert cv2.imwrite(str(image_path), img)

    with session_scope() as session:
        image = Image(
            file_path=str(image_path),
            file_hash="hash",
            file_mtime=image_path.stat().st_mtime,
        )
        session.add(image)
        session.flush()
        image_id = image.id

    captured_indexes: list[int] = []

    def fake_save_face_crop(
        img_bgr,
        detection,
        crops_dir,
        image_id,
        thumbnail_size,
        face_index=0,
    ):
        captured_indexes.append(face_index)
        return Path(crops_dir) / f"img{image_id:06d}_face{face_index:03d}.jpg"

    monkeypatch.setattr(
        "app.services.detection_service.save_face_crop",
        fake_save_face_crop,
    )

    cfg = AppConfig(base_dir=str(tmp_path))
    cfg.storage.db_path = str(db_path)
    cfg.storage.crops_dir = "crops"

    with session_scope() as session:
        service = DetectionService(
            session=session,
            detector=_DummyDetector(),
            config=cfg,
        )
        detected = service.process([image_id])

    assert detected == 2
    assert captured_indexes == [0, 1]

    with session_scope() as session:
        faces = session.query(Face).order_by(Face.id).all()

    assert len(faces) == 2
    assert faces[0].crop_path != faces[1].crop_path
    assert faces[0].crop_path.endswith("face000.jpg")
    assert faces[1].crop_path.endswith("face001.jpg")
