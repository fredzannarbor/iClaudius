#!/usr/bin/env python3
"""
Generate an I, Claudius inspired app icon for iClaudius.

The icon features:
- The letter "C" in a classical serif font (for Claude/Claudius)
- Roman purple/gold color scheme
- Imperial styling without the laurel wreath
"""

from PIL import Image, ImageDraw, ImageFont
import subprocess
import math
import os
import shutil

def create_claudius_icon(size=1024):
    """Create an I, Claudius inspired icon - clean Roman imperial style."""

    # Create base image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2
    margin = size // 10

    # Background: Rich Roman purple gradient effect
    for i in range(size):
        ratio = i / size
        r = int(88 + (40 * ratio))  # Dark purple to lighter
        g = int(28 + (20 * ratio))
        b = int(108 + (30 * ratio))
        draw.line([(0, i), (size, i)], fill=(r, g, b, 255))

    # Gold color
    gold = (212, 175, 55)
    dark_gold = (180, 145, 35)

    # Draw circular border (gold) - double line for imperial look
    outer_border = size // 30
    inner_border = size // 40

    # Outer gold ring
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        outline=gold,
        width=outer_border
    )

    # Inner gold ring
    inner_margin = margin + outer_border + size // 50
    draw.ellipse(
        [inner_margin, inner_margin, size - inner_margin, size - inner_margin],
        outline=dark_gold,
        width=inner_border
    )

    # Draw the letter "C" in the center - large and prominent
    try:
        font_size = int(size * 0.55)
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Times.ttc", font_size)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Times New Roman.ttf", font_size)
            except:
                font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    text = "C"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    text_x = center - text_width // 2
    text_y = center - text_height // 2 - size // 25

    # Shadow for depth
    shadow_offset = size // 60
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text, font=font, fill=(20, 20, 20, 200))

    # Main text in gold
    draw.text((text_x, text_y), text, font=font, fill=gold)

    # Add subtle decorative dots around the border (Roman coin style)
    dot_radius = size // 80
    num_dots = 24
    dot_distance = size // 2 - margin - size // 15

    for i in range(num_dots):
        angle = (i / num_dots) * 2 * math.pi - math.pi / 2
        x = center + math.cos(angle) * dot_distance
        y = center + math.sin(angle) * dot_distance
        draw.ellipse(
            [x - dot_radius, y - dot_radius, x + dot_radius, y + dot_radius],
            fill=dark_gold
        )

    return img


def create_icns(source_image, output_path):
    """Create an icns file from the source image."""
    sizes = [16, 32, 64, 128, 256, 512, 1024]

    # Create iconset directory
    iconset_path = output_path.replace('.icns', '.iconset')
    os.makedirs(iconset_path, exist_ok=True)

    for size in sizes:
        resized = source_image.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_path, f'icon_{size}x{size}.png'))

        if size <= 512:
            resized_2x = source_image.resize((size * 2, size * 2), Image.Resampling.LANCZOS)
            resized_2x.save(os.path.join(iconset_path, f'icon_{size}x{size}@2x.png'))

    # Convert to icns using iconutil (safe subprocess call)
    subprocess.run(['iconutil', '-c', 'icns', iconset_path, '-o', output_path], check=True)

    # Clean up iconset
    shutil.rmtree(iconset_path)


if __name__ == '__main__':
    # Generate the icon
    icon = create_claudius_icon(1024)

    # Save as PNG
    png_path = os.path.expanduser('~/xcode_projects/iClaudius/AppIcon.png')
    icon.save(png_path)
    print(f"Saved PNG: {png_path}")

    # Create icns
    icns_path = os.path.expanduser('~/xcode_projects/iClaudius/iClaudius.app/Contents/Resources/AppIcon.icns')
    os.makedirs(os.path.dirname(icns_path), exist_ok=True)
    create_icns(icon, icns_path)
    print(f"Saved ICNS: {icns_path}")

    print("Icon generation complete!")
