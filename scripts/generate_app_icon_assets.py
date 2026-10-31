#!/usr/bin/env python3
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "AppIcon.xcassets" / "AppIcon.appiconset"
ASSET_DIR.mkdir(parents=True, exist_ok=True)

image_specs = {
    "Icon-20@2x.png": (40, 40),
    "Icon-20@3x.png": (60, 60),
    "Icon-29@2x.png": (58, 58),
    "Icon-29@3x.png": (87, 87),
    "Icon-40@2x.png": (80, 80),
    "Icon-40@3x.png": (120, 120),
    "Icon-60@2x.png": (120, 120),
    "Icon-60@3x.png": (180, 180),
    "Icon-76.png": (76, 76),
    "Icon-76@2x.png": (152, 152),
    "Icon-83.5@2x.png": (167, 167),
    "Icon-1024.png": (1024, 1024),
}

# Create a simple icon matching the attached design: light gray background,
# rounded corners, and large stacked "TOKEN / SAVER" text.

def create_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (243, 243, 243, 255))
    draw = ImageDraw.Draw(image)

    pad = size * 0.10
    radius = size * 0.18
    draw.rounded_rectangle(
        [(pad / 2, pad / 2), (size - pad / 2, size - pad / 2)],
        radius=radius,
        fill=(244, 244, 244, 255),
        outline=(230, 230, 230, 255),
        width=max(2, size // 80),
    )

    # Large black text split into two lines.
    font_size = max(22, int(size * 0.22))
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", font_size)
    except OSError:
        font = ImageFont.load_default()

    text_color = (26, 26, 26, 255)
    text_top = "TOKEN"
    text_bottom = "SAVER"

    # Use placement tuned for the original square style.
    for label, y_offset in [(text_top, 0.32), (text_bottom, 0.60)]:
        bbox = draw.textbbox((0, 0), label, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        x = (size - text_w) / 2
        y = (size * y_offset) - (text_h / 2)
        draw.text((x, y), label, fill=text_color, font=font)

    return image

for filename, (width, height) in image_specs.items():
    icon = create_icon(max(width, height))
    icon = icon.resize((width, height), Image.LANCZOS)
    icon.save(ASSET_DIR / filename)

contents = {
    "images": [
        {"idiom": "iphone", "size": "20x20", "scale": "2x", "filename": "Icon-20@2x.png"},
        {"idiom": "iphone", "size": "20x20", "scale": "3x", "filename": "Icon-20@3x.png"},
        {"idiom": "iphone", "size": "29x29", "scale": "2x", "filename": "Icon-29@2x.png"},
        {"idiom": "iphone", "size": "29x29", "scale": "3x", "filename": "Icon-29@3x.png"},
        {"idiom": "iphone", "size": "40x40", "scale": "2x", "filename": "Icon-40@2x.png"},
        {"idiom": "iphone", "size": "40x40", "scale": "3x", "filename": "Icon-40@3x.png"},
        {"idiom": "iphone", "size": "60x60", "scale": "2x", "filename": "Icon-60@2x.png"},
        {"idiom": "iphone", "size": "60x60", "scale": "3x", "filename": "Icon-60@3x.png"},
        {"idiom": "ipad", "size": "20x20", "scale": "1x", "filename": "Icon-20@2x.png"},
        {"idiom": "ipad", "size": "20x20", "scale": "2x", "filename": "Icon-20@2x.png"},
        {"idiom": "ipad", "size": "29x29", "scale": "1x", "filename": "Icon-29@2x.png"},
        {"idiom": "ipad", "size": "29x29", "scale": "2x", "filename": "Icon-29@2x.png"},
        {"idiom": "ipad", "size": "40x40", "scale": "1x", "filename": "Icon-40@2x.png"},
        {"idiom": "ipad", "size": "40x40", "scale": "2x", "filename": "Icon-40@2x.png"},
        {"idiom": "ipad", "size": "76x76", "scale": "1x", "filename": "Icon-76.png"},
        {"idiom": "ipad", "size": "76x76", "scale": "2x", "filename": "Icon-76@2x.png"},
        {"idiom": "ipad", "size": "83.5x83.5", "scale": "2x", "filename": "Icon-83.5@2x.png"},
        {"idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "Icon-1024.png"},
    ],
    "info": {"version": 1, "author": "xcode"},
}

(ASSET_DIR / "Contents.json").write_text(json.dumps(contents, indent=2))
print(f"Generated app icon assets in {ASSET_DIR}")
