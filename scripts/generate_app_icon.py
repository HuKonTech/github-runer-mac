#!/usr/bin/env python3
"""Generate application icon assets for Face-Local."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT / "assets"
MASTER_ICON_PATH = ASSETS_DIR / "app_icon.png"
WINDOWS_ICON_PATH = ASSETS_DIR / "app_icon.ico"
MACOS_ICON_PATH = ASSETS_DIR / "app_icon.icns"
LINUX_ICON_PATH = ASSETS_DIR / "face-local.png"


def main() -> None:
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    master = build_master_icon(1024)
    master.save(MASTER_ICON_PATH)
    master.resize((512, 512), Image.Resampling.LANCZOS).save(LINUX_ICON_PATH)
    master.save(
        WINDOWS_ICON_PATH,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    master.save(MACOS_ICON_PATH, format="ICNS")


def build_master_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    content = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(content)

    _draw_background(content, size)
    _draw_face_silhouette(content, size)
    _draw_focus_brackets(draw, size)
    _draw_cluster_nodes(draw, size)
    _draw_inner_glow(content, size)

    radius = int(size * 0.22)
    rounded_mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(rounded_mask)
    mask_draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    image.paste(content, (0, 0), rounded_mask)
    return image


def _draw_background(image: Image.Image, size: int) -> None:
    draw = ImageDraw.Draw(image)
    for y in range(size):
        ratio = y / max(size - 1, 1)
        top = (11, 30, 48)
        bottom = (27, 92, 95)
        line = tuple(int(top[i] * (1.0 - ratio) + bottom[i] * ratio) for i in range(3))
        draw.line((0, y, size, y), fill=line + (255,), width=1)

    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse(
        (
            int(size * 0.10),
            int(size * 0.06),
            int(size * 0.92),
            int(size * 0.88),
        ),
        fill=(76, 181, 192, 92),
    )
    halo_draw.ellipse(
        (
            int(size * 0.28),
            int(size * 0.08),
            int(size * 0.88),
            int(size * 0.64),
        ),
        fill=(241, 176, 102, 58),
    )
    halo = halo.filter(ImageFilter.GaussianBlur(radius=size * 0.08))
    image.alpha_composite(halo)

    vignette = Image.new("L", (size, size), 255)
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.ellipse(
        (
            int(size * -0.10),
            int(size * -0.06),
            int(size * 1.10),
            int(size * 1.18),
        ),
        fill=0,
    )
    vignette = ImageChops.invert(vignette).filter(ImageFilter.GaussianBlur(radius=size * 0.09))
    shadow = Image.new("RGBA", (size, size), (3, 12, 18, 165))
    image.paste(shadow, (0, 0), vignette)


def _draw_face_silhouette(image: Image.Image, size: int) -> None:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    center_x = size * 0.44
    head_radius = size * 0.12
    head_box = (
        center_x - head_radius,
        size * 0.26 - head_radius,
        center_x + head_radius,
        size * 0.26 + head_radius,
    )
    draw.ellipse(head_box, fill=(243, 248, 245, 255))

    shoulder_box = (
        size * 0.22,
        size * 0.39,
        size * 0.66,
        size * 0.76,
    )
    draw.rounded_rectangle(
        shoulder_box,
        radius=int(size * 0.10),
        fill=(243, 248, 245, 255),
    )
    cutout = (
        size * 0.26,
        size * 0.47,
        size * 0.62,
        size * 0.80,
    )
    alpha = layer.getchannel("A")
    alpha_draw = ImageDraw.Draw(alpha)
    alpha_draw.ellipse(cutout, fill=0)
    layer.putalpha(alpha)

    accent_box = (
        size * 0.28,
        size * 0.45,
        size * 0.60,
        size * 0.72,
    )
    draw.arc(
        accent_box,
        start=190,
        end=350,
        fill=(151, 233, 227, 235),
        width=max(8, int(size * 0.018)),
    )
    image.alpha_composite(layer)


def _draw_focus_brackets(draw: ImageDraw.ImageDraw, size: int) -> None:
    stroke = max(10, int(size * 0.02))
    color = (242, 178, 92, 255)
    left = size * 0.14
    top = size * 0.22
    width = size * 0.44
    height = size * 0.46
    corner = size * 0.09
    segments = [
        (left, top + corner, left, top, left + corner, top),
        (left + width - corner, top, left + width, top, left + width, top + corner),
        (
            left,
            top + height - corner,
            left,
            top + height,
            left + corner,
            top + height,
        ),
        (
            left + width - corner,
            top + height,
            left + width,
            top + height,
            left + width,
            top + height - corner,
        ),
    ]
    for x1, y1, x2, y2, x3, y3 in segments:
        draw.line((x1, y1, x2, y2), fill=color, width=stroke)
        draw.line((x2, y2, x3, y3), fill=color, width=stroke)


def _draw_cluster_nodes(draw: ImageDraw.ImageDraw, size: int) -> None:
    nodes = [
        ((0.71, 0.34), 0.05, (97, 223, 218, 255)),
        ((0.80, 0.48), 0.042, (242, 178, 92, 255)),
        ((0.69, 0.62), 0.036, (186, 246, 238, 255)),
    ]
    line_color = (212, 242, 240, 210)
    width = max(6, int(size * 0.012))

    centers: list[tuple[float, float]] = []
    for (x_ratio, y_ratio), radius_ratio, color in nodes:
        x = size * x_ratio
        y = size * y_ratio
        centers.append((x, y))
        radius = size * radius_ratio
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
        ring = max(4, int(size * 0.008))
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            outline=(244, 250, 248, 230),
            width=ring,
        )

    draw.line((*centers[0], *centers[1]), fill=line_color, width=width)
    draw.line((*centers[1], *centers[2]), fill=line_color, width=width)
    draw.line((*centers[0], *centers[2]), fill=(157, 227, 222, 150), width=max(4, width // 2))


def _draw_inner_glow(image: Image.Image, size: int) -> None:
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.rounded_rectangle(
        (
            int(size * 0.03),
            int(size * 0.03),
            int(size * 0.97),
            int(size * 0.97),
        ),
        radius=int(size * 0.20),
        outline=(255, 255, 255, 44),
        width=max(4, int(size * 0.012)),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.014))
    image.alpha_composite(glow)


if __name__ == "__main__":
    main()
