"""Export service.

Exports face images and metadata for a selected person (or all persons).
Output formats:
  * Image folder — copies all face crops (or original images) to a target dir.
  * CSV report — face-level metadata table.
  * JSON report — structured person/face records.
"""

from __future__ import annotations

import csv
import html as html_module
import json
import logging
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import cv2

from sqlalchemy.orm import Session

from app.db.models import Face, Person

log = logging.getLogger(__name__)


class ExportService:
    """Exports faces and metadata for one or all persons.

    Args:
        session: SQLAlchemy session.
    """

    def __init__(self, session: Session) -> None:
        self._session = session

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def export_person_images(
        self,
        person_id: int,
        target_dir: str,
        copy_originals: bool = False,
    ) -> int:
        """Copy face crops (or original images) for *person_id* to *target_dir*.

        Args:
            person_id:       Person to export.
            target_dir:      Destination directory (created if absent).
            copy_originals:  If ``True``, copy the full original image instead
                             of just the face crop thumbnail.

        Returns:
            Number of files copied.
        """
        person = self._session.get(Person, person_id)
        if person is None:
            raise ValueError(f"Person id={person_id} not found")

        dest = Path(target_dir)
        dest.mkdir(parents=True, exist_ok=True)

        faces = self._get_faces(person_id)
        copied = 0

        for face in faces:
            src = self._resolve_source(face, copy_originals)
            if src is None or not src.exists():
                log.debug("Source missing for face %d — skipping", face.id)
                continue

            dst_name = f"face_{face.id}_{src.name}"
            dst = dest / dst_name
            shutil.copy2(src, dst)
            copied += 1

        log.info(
            "Exported %d image(s) for person %r to %s", copied, person.name, dest
        )
        return copied

    def export_csv(
        self,
        target_path: str,
        person_id: Optional[int] = None,
    ) -> Path:
        """Write a CSV report to *target_path*.

        Columns: person_id, person_name, face_id, image_path, bbox_x, bbox_y,
                 bbox_w, bbox_h, confidence, detector_backend, crop_path.

        Args:
            target_path: Destination ``.csv`` file path.
            person_id:   Export only this person.  ``None`` → all persons.

        Returns:
            Path to the written CSV file.
        """
        rows = self._build_rows(person_id)
        out = Path(target_path)
        out.parent.mkdir(parents=True, exist_ok=True)

        fieldnames = [
            "person_id", "person_name", "face_id",
            "image_path", "bbox_x", "bbox_y", "bbox_w", "bbox_h",
            "confidence", "detector_backend", "crop_path",
        ]

        with open(out, "w", newline="", encoding="utf-8") as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        log.info("CSV export: %d row(s) → %s", len(rows), out)
        return out

    def export_json(
        self,
        target_path: str,
        person_id: Optional[int] = None,
    ) -> Path:
        """Write a JSON report to *target_path*.

        Structure::

            [
              {
                "person_id": 1,
                "person_name": "Alice",
                "faces": [
                  {
                    "face_id": 42,
                    "image_path": "/path/to/photo.jpg",
                    "bbox": [x, y, w, h],
                    "confidence": 0.97,
                    "detector_backend": "coral",
                    "crop_path": "/path/to/crop.jpg"
                  },
                  ...
                ]
              },
              ...
            ]
        """
        persons = self._get_persons(person_id)
        records = []

        for person in persons:
            faces = self._get_faces(person.id)
            face_records = []
            for f in faces:
                face_records.append(
                    {
                        "face_id": f.id,
                        "image_path": f.image.file_path if f.image else None,
                        "bbox": [f.bbox_x, f.bbox_y, f.bbox_w, f.bbox_h],
                        "confidence": round(f.confidence, 4),
                        "detector_backend": f.detector_backend,
                        "crop_path": f.crop_path,
                    }
                )
            records.append(
                {
                    "person_id": person.id,
                    "person_name": person.name,
                    "faces": face_records,
                }
            )

        out = Path(target_path)
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, "w", encoding="utf-8") as fh:
            json.dump(records, fh, indent=2, ensure_ascii=False)

        log.info("JSON export: %d person(s) → %s", len(records), out)
        return out

    def export_html(
        self,
        target_dir: str,
        person_id: Optional[int] = None,
    ) -> Path:
        """Generate a static HTML gallery to *target_dir*.

        Creates:
          index.html   – searchable gallery with per-person filtering
          images/      – annotated originals (face boxes + names burned in)
          thumbs/      – face-crop thumbnails
        """
        out = Path(target_dir)
        img_dir = out / "images"
        thumb_dir = out / "thumbs"
        img_dir.mkdir(parents=True, exist_ok=True)
        thumb_dir.mkdir(parents=True, exist_ok=True)

        persons = self._get_persons(person_id)

        # --- build data structures ---
        # image_path → list of (person_name, bbox)
        image_faces: Dict[str, List[Tuple[str, Tuple[int,int,int,int]]]] = {}
        # person_name → list of thumb filenames
        person_thumbs: Dict[str, List[str]] = {}
        # person_name → set of annotated image filenames
        person_images: Dict[str, List[str]] = {}

        for person in persons:
            faces = self._get_faces(person.id)
            person_thumbs.setdefault(person.name, [])
            person_images.setdefault(person.name, [])
            for face in faces:
                if face.image:
                    ip = face.image.file_path
                    image_faces.setdefault(ip, []).append(
                        (person.name, (face.bbox_x, face.bbox_y, face.bbox_w, face.bbox_h))
                    )
                if face.crop_path and Path(face.crop_path).exists():
                    dst_thumb = thumb_dir / f"face_{face.id}.jpg"
                    shutil.copy2(face.crop_path, dst_thumb)
                    person_thumbs[person.name].append(dst_thumb.name)

        # --- render annotated originals ---
        for img_path, face_list in image_faces.items():
            src = Path(img_path)
            img = cv2.imread(img_path)
            if img is None:
                continue
            for pname, (x, y, w, h) in face_list:
                cv2.rectangle(img, (x, y), (x + w, y + h), (50, 200, 50), 3)
                font = cv2.FONT_HERSHEY_SIMPLEX
                scale = max(0.4, min(1.2, w / 80))
                (tw, th), bl = cv2.getTextSize(pname, font, scale, 2)
                ty = max(y - 6, th + 6)
                cv2.rectangle(img, (x, ty - th - bl - 4), (x + tw + 6, ty + 2), (20, 20, 20), -1)
                cv2.putText(img, pname, (x + 3, ty - bl), font, scale, (50, 220, 50), 2)

            dst_name = f"img_{abs(hash(img_path))}.jpg"
            cv2.imwrite(str(img_dir / dst_name), img)
            for pname, _ in face_list:
                if dst_name not in person_images.get(pname, []):
                    person_images.setdefault(pname, []).append(dst_name)

        # --- build JS data ---
        js_persons = json.dumps(
            [
                {
                    "name": pname,
                    "thumbs": person_thumbs.get(pname, []),
                    "images": person_images.get(pname, []),
                }
                for pname in sorted(person_thumbs.keys())
            ],
            ensure_ascii=False,
        )

        # --- render HTML ---
        html = _HTML_TEMPLATE.replace("__PERSONS_JSON__", js_persons)
        (out / "index.html").write_text(html, encoding="utf-8")

        log.info("HTML export: %d person(s) → %s", len(persons), out)
        return out

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _get_persons(self, person_id: Optional[int]) -> List[Person]:
        if person_id is not None:
            p = self._session.get(Person, person_id)
            return [p] if p else []
        return self._session.query(Person).order_by(Person.name).all()

    def _get_faces(self, person_id: int) -> List[Face]:
        return (
            self._session.query(Face)
            .filter(Face.person_id == person_id)
            .all()
        )

    @staticmethod
    def _resolve_source(face: Face, copy_originals: bool) -> Optional[Path]:
        if copy_originals and face.image:
            return Path(face.image.file_path)
        if face.crop_path:
            return Path(face.crop_path)
        return None

    def _build_rows(self, person_id: Optional[int]) -> List[dict]:
        persons = self._get_persons(person_id)
        rows = []
        for person in persons:
            for face in self._get_faces(person.id):
                rows.append(
                    {
                        "person_id": person.id,
                        "person_name": person.name,
                        "face_id": face.id,
                        "image_path": face.image.file_path if face.image else "",
                        "bbox_x": face.bbox_x,
                        "bbox_y": face.bbox_y,
                        "bbox_w": face.bbox_w,
                        "bbox_h": face.bbox_h,
                        "confidence": round(face.confidence, 4),
                        "detector_backend": face.detector_backend,
                        "crop_path": face.crop_path or "",
                    }
                )
        return rows


# ---------------------------------------------------------------------------
# Static HTML template
# ---------------------------------------------------------------------------

_HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="hu">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Face Gallery</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:#111;color:#ddd;font-family:system-ui,sans-serif}
  header{background:#1a1a1a;padding:16px 24px;border-bottom:1px solid #333;
         display:flex;align-items:center;gap:16px;flex-wrap:wrap}
  header h1{font-size:1.2rem;color:#88aaff;white-space:nowrap}
  #search{flex:1;min-width:180px;padding:8px 12px;background:#222;
          border:1px solid #444;border-radius:6px;color:#fff;font-size:1rem}
  #search:focus{outline:none;border-color:#88aaff}
  #count{font-size:.85rem;color:#888;white-space:nowrap}

  #persons{display:flex;flex-wrap:wrap;gap:20px;padding:20px}
  .person-card{background:#1c1c1c;border:1px solid #333;border-radius:8px;
               padding:14px;width:260px;transition:border-color .2s}
  .person-card.hidden{display:none}
  .person-card:hover{border-color:#88aaff}
  .person-name{font-weight:bold;font-size:1rem;margin-bottom:10px;color:#eee}
  .thumbs{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:10px}
  .thumbs img{width:56px;height:56px;object-fit:cover;border-radius:4px;
              border:1px solid #444;cursor:pointer;transition:border-color .2s}
  .thumbs img:hover{border-color:#88aaff}
  .images-label{font-size:.75rem;color:#888;margin-bottom:6px}
  .img-strip{display:flex;flex-wrap:wrap;gap:4px}
  .img-strip img{height:80px;border-radius:4px;border:1px solid #333;
                 cursor:pointer;transition:opacity .2s;object-fit:cover}
  .img-strip img:hover{opacity:.85;border-color:#88aaff}

  /* lightbox */
  #lb{display:none;position:fixed;inset:0;background:rgba(0,0,0,.88);
      z-index:100;align-items:center;justify-content:center;flex-direction:column;gap:12px}
  #lb.open{display:flex}
  #lb img{max-width:92vw;max-height:86vh;border-radius:6px;border:2px solid #88aaff}
  #lb-close{position:fixed;top:16px;right:20px;font-size:2rem;cursor:pointer;
             color:#aaa;line-height:1;background:none;border:none}
  #lb-close:hover{color:#fff}
</style>
</head>
<body>
<header>
  <h1>Face Gallery</h1>
  <input id="search" type="text" placeholder="Keresés / Search…" oninput="filter()">
  <span id="count"></span>
</header>
<div id="persons"></div>

<!-- lightbox -->
<div id="lb"><button id="lb-close" onclick="closeLb()">✕</button><img id="lb-img" src=""></div>

<script>
const PERSONS = __PERSONS_JSON__;

function openLb(src){
  document.getElementById('lb-img').src=src;
  document.getElementById('lb').classList.add('open');
}
function closeLb(){document.getElementById('lb').classList.remove('open');}
document.getElementById('lb').addEventListener('click',function(e){
  if(e.target===this)closeLb();
});
document.addEventListener('keydown',function(e){if(e.key==='Escape')closeLb();});

function buildCards(){
  const wrap=document.getElementById('persons');
  wrap.innerHTML='';
  PERSONS.forEach(p=>{
    const card=document.createElement('div');
    card.className='person-card';
    card.dataset.name=p.name.toLowerCase();

    const nameEl=document.createElement('div');
    nameEl.className='person-name';
    nameEl.textContent=p.name+' ('+p.images.length+' kép)';
    card.appendChild(nameEl);

    if(p.thumbs.length){
      const thumbs=document.createElement('div');
      thumbs.className='thumbs';
      p.thumbs.forEach(t=>{
        const img=document.createElement('img');
        img.src='thumbs/'+t;
        img.title=p.name;
        img.onclick=()=>openLb('thumbs/'+t);
        thumbs.appendChild(img);
      });
      card.appendChild(thumbs);
    }

    if(p.images.length){
      const lbl=document.createElement('div');
      lbl.className='images-label';
      lbl.textContent='Eredeti képek / Original photos:';
      card.appendChild(lbl);
      const strip=document.createElement('div');
      strip.className='img-strip';
      p.images.forEach(im=>{
        const img=document.createElement('img');
        img.src='images/'+im;
        img.title=p.name;
        img.onclick=()=>openLb('images/'+im);
        strip.appendChild(img);
      });
      card.appendChild(strip);
    }

    wrap.appendChild(card);
  });
  updateCount();
}

function filter(){
  const q=document.getElementById('search').value.toLowerCase().trim();
  document.querySelectorAll('.person-card').forEach(c=>{
    c.classList.toggle('hidden', q && !c.dataset.name.includes(q));
  });
  updateCount();
}

function updateCount(){
  const total=document.querySelectorAll('.person-card').length;
  const vis=document.querySelectorAll('.person-card:not(.hidden)').length;
  document.getElementById('count').textContent=vis+' / '+total+' személy';
}

buildCards();
</script>
</body>
</html>
"""
