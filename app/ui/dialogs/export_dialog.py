"""Export dialog — CSV, JSON and image export in one place."""

from __future__ import annotations

from pathlib import Path
from typing import Optional

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QCheckBox,
    QDialog,
    QFileDialog,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QRadioButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from app.db.database import session_scope
from app.services.export_service import ExportService


class ExportDialog(QDialog):
    """Modal export window with CSV, JSON and image export options."""

    def __init__(
        self,
        current_person_id: Optional[int] = None,
        current_person_name: Optional[str] = None,
        parent: Optional[QWidget] = None,
    ) -> None:
        super().__init__(parent)
        self._person_id = current_person_id
        self._person_name = current_person_name
        self.setWindowTitle("Exportálás / Export")
        self.setMinimumWidth(500)
        self._build_ui()

    # ------------------------------------------------------------------

    def _build_ui(self) -> None:
        layout = QVBoxLayout(self)
        layout.setSpacing(12)

        # --- Scope ---
        scope_box = QGroupBox("Hatókör / Scope")
        scope_layout = QVBoxLayout(scope_box)
        self._all_radio = QRadioButton("Összes személy / All persons")
        self._cur_radio = QRadioButton(
            f"Csak a kiválasztott: {self._person_name or '—'}  /  Selected person only"
        )
        self._cur_radio.setEnabled(self._person_id is not None)
        self._all_radio.setChecked(True)
        scope_layout.addWidget(self._all_radio)
        scope_layout.addWidget(self._cur_radio)
        layout.addWidget(scope_box)

        # --- CSV ---
        csv_box = QGroupBox("CSV export")
        csv_layout = QVBoxLayout(csv_box)
        csv_desc = QLabel(
            "Metaadat táblázat: személy, arc, bounding box, konfidencia.\n"
            "Metadata table: person, face, bounding box, confidence."
        )
        csv_desc.setWordWrap(True)
        csv_desc.setStyleSheet("color: #aaa; font-size: 11px;")
        csv_layout.addWidget(csv_desc)
        self._csv_btn = QPushButton("💾  CSV mentése…  /  Save CSV…")
        self._csv_btn.clicked.connect(self._on_export_csv)
        csv_layout.addWidget(self._csv_btn)
        layout.addWidget(csv_box)

        # --- JSON ---
        json_box = QGroupBox("JSON export")
        json_layout = QVBoxLayout(json_box)
        json_desc = QLabel(
            "Strukturált JSON: személyenként csoportosított arcok.\n"
            "Structured JSON: faces grouped per person."
        )
        json_desc.setWordWrap(True)
        json_desc.setStyleSheet("color: #aaa; font-size: 11px;")
        json_layout.addWidget(json_desc)
        self._json_btn = QPushButton("💾  JSON mentése…  /  Save JSON…")
        self._json_btn.clicked.connect(self._on_export_json)
        json_layout.addWidget(self._json_btn)
        layout.addWidget(json_box)

        # --- Images ---
        img_box = QGroupBox("Képek exportálása / Export Images")
        img_layout = QVBoxLayout(img_box)
        img_desc = QLabel(
            "Arc kivágások másolása egy mappába.\n"
            "Copy face crop thumbnails to a folder."
        )
        img_desc.setWordWrap(True)
        img_desc.setStyleSheet("color: #aaa; font-size: 11px;")
        img_layout.addWidget(img_desc)
        self._images_btn = QPushButton("📁  Mappa kiválasztása…  /  Choose folder…")
        self._images_btn.setEnabled(self._person_id is not None)
        if self._person_id is None:
            self._images_btn.setToolTip(
                "Válassz ki egy személyt a főablakban / Select a person in the main window"
            )
        self._images_btn.clicked.connect(self._on_export_images)
        img_layout.addWidget(self._images_btn)
        layout.addWidget(img_box)

        # --- HTML gallery ---
        html_box = QGroupBox("Statikus weboldal / Static HTML Gallery")
        html_layout = QVBoxLayout(html_box)
        html_desc = QLabel(
            "Böngészőben megnyitható galéria: személyek, arc-kivágások, "
            "és az eredeti képek beégetett névfeliratokkal. Keresés is elérhető.\n"
            "Browser gallery: persons, crops, annotated originals with burned-in names. Searchable."
        )
        html_desc.setWordWrap(True)
        html_desc.setStyleSheet("color: #aaa; font-size: 11px;")
        html_layout.addWidget(html_desc)
        self._html_btn = QPushButton("🌐  HTML galéria generálása…  /  Generate HTML gallery…")
        self._html_btn.clicked.connect(self._on_export_html)
        html_layout.addWidget(self._html_btn)
        layout.addWidget(html_box)

        # --- Close ---
        close_btn = QPushButton("Bezárás / Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn, alignment=Qt.AlignRight)

    # ------------------------------------------------------------------

    def _scope_person_id(self) -> Optional[int]:
        return self._person_id if self._cur_radio.isChecked() else None

    def _on_export_csv(self) -> None:
        path, _ = QFileDialog.getSaveFileName(
            self, "CSV mentése / Save CSV", "export.csv", "CSV Files (*.csv)"
        )
        if not path:
            return
        with session_scope() as session:
            out = ExportService(session).export_csv(
                target_path=path, person_id=self._scope_person_id()
            )
        QMessageBox.information(self, "CSV exportálva", f"Mentve:\n{out}")

    def _on_export_json(self) -> None:
        path, _ = QFileDialog.getSaveFileName(
            self, "JSON mentése / Save JSON", "export.json", "JSON Files (*.json)"
        )
        if not path:
            return
        with session_scope() as session:
            out = ExportService(session).export_json(
                target_path=path, person_id=self._scope_person_id()
            )
        QMessageBox.information(self, "JSON exportálva", f"Mentve:\n{out}")

    def _on_export_html(self) -> None:
        folder = QFileDialog.getExistingDirectory(
            self, "HTML galéria mappája / HTML gallery folder", str(Path.home())
        )
        if not folder:
            return
        import subprocess, sys
        with session_scope() as session:
            out = ExportService(session).export_html(
                target_dir=folder, person_id=self._scope_person_id()
            )
        index = out / "index.html"
        reply = QMessageBox.information(
            self,
            "HTML galéria kész",
            f"Generálva:\n{index}\n\nMegnyitod a böngészőben?",
            QMessageBox.Yes | QMessageBox.No,
        )
        if reply == QMessageBox.Yes:
            if sys.platform == "darwin":
                subprocess.Popen(["open", str(index)])
            elif sys.platform == "win32":
                subprocess.Popen(["start", str(index)], shell=True)
            else:
                subprocess.Popen(["xdg-open", str(index)])

    def _on_export_images(self) -> None:
        if self._person_id is None:
            return
        folder = QFileDialog.getExistingDirectory(
            self, "Mappa kiválasztása / Choose folder", str(Path.home())
        )
        if not folder:
            return
        with session_scope() as session:
            n = ExportService(session).export_person_images(
                person_id=self._person_id, target_dir=folder
            )
        QMessageBox.information(
            self, "Képek exportálva", f"{n} fájl másolva / files copied:\n{folder}"
        )
