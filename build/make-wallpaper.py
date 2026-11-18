#!/usr/bin/env python3
"""Generate the ARMOS 1.0 "GEN" desktop wallpapers.

The look is deliberately restrained: graphite base, a faint blueprint grid, and
one oversized ARMOS "A" monogram with its orbital ring rendered as low-opacity
line art. No neon, no glow, no strong gradients — the muted blue accent appears
once, on the monogram crossbar and the orbital ring.
"""

import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

BASE_W, BASE_H = 3840, 2400

GRAPHITE = (14, 16, 20)
GRAPHITE_LIFT = (20, 24, 30)
INK = (230, 234, 240)
ACCENT = (76, 141, 255)


def vertical_gradient(width, height, top, bottom):
    grad = Image.new("RGB", (1, height))
    px = grad.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        px[0, y] = tuple(
            round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)
        )
    return grad.resize((width, height), Image.BILINEAR)


def radial_light(width, height, center, radius, color, strength):
    """Additive soft disc, used to lift the middle of the canvas slightly."""
    layer = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    steps = 48
    for i in range(steps, 0, -1):
        r = radius * i / steps
        alpha = int(strength * (1 - i / steps) ** 2 * 255)
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r], fill=alpha
        )
    layer = layer.filter(ImageFilter.GaussianBlur(120))
    tint = Image.new("RGB", (width, height), color)
    return Image.composite(tint, Image.new("RGB", (width, height), (0, 0, 0)), layer)


def add_grid(image, step=160):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    hair = (255, 255, 255, 7)
    width, height = image.size
    for x in range(0, width, step):
        draw.line([(x, 0), (x, height)], fill=hair, width=1)
    for y in range(0, height, step):
        draw.line([(0, y), (width, y)], fill=hair, width=1)
    return Image.alpha_composite(image.convert("RGBA"), layer)


def line_layer(size, points, width, color, alpha):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rgba = color + (alpha,)
    draw.line(points, fill=rgba, width=width, joint="curve")
    radius = width // 2
    for x, y in (points[0], points[-1]):
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=rgba)
    return layer


def monogram(size, stroke, accent_stroke):
    """The ARMOS A mark as line art, drawn on a transparent square layer."""
    s = size
    pad = int(s * 0.12)
    top = (s // 2, pad)
    left = (pad + int(s * 0.03), s - pad)
    right = (s - pad - int(s * 0.03), s - pad)
    t = (left[1] - top[1])
    cross_y = top[1] + int(t * 0.66)
    k = (cross_y - top[1]) / t
    x_left = top[0] + (left[0] - top[0]) * k
    x_right = top[0] + (right[0] - top[0]) * k
    cross = [(int(x_left), cross_y), (int(x_right), cross_y)]

    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    layer = Image.alpha_composite(
        layer, line_layer((s, s), [left, top, right], stroke, INK, 26)
    )
    layer = Image.alpha_composite(
        layer, line_layer((s, s), cross, accent_stroke, ACCENT, 46)
    )
    return layer


def orbital_ring(size, stroke, alpha):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rx, ry = int(size * 0.47), int(size * 0.185)
    box = [size // 2 - rx, size // 2 - ry, size // 2 + rx, size // 2 + ry]
    draw.ellipse(box, outline=ACCENT + (alpha,), width=stroke)
    # Node dot sitting on the ring, slightly ahead of the top-right.
    angle = math.radians(-22 + 38)
    ex = size // 2 + rx * math.cos(angle)
    ey = size // 2 + ry * math.sin(angle)
    r = stroke * 1.6
    draw.ellipse([ex - r, ey - r, ex + r, ey + r], fill=ACCENT + (min(255, alpha + 90),))
    return layer.rotate(-22, resample=Image.BICUBIC, expand=False)


def compose(width, height):
    canvas = vertical_gradient(width, height, GRAPHITE_LIFT, GRAPHITE)
    lift = radial_light(
        width, height, (width * 0.66, height * 0.44), int(height * 0.95),
        (28, 34, 46), 0.55,
    )
    canvas = ImageChops.add(canvas, lift)
    canvas = add_grid(canvas)

    mark_size = int(height * 0.86)
    stroke = max(6, mark_size // 34)
    accent_stroke = max(4, mark_size // 62)
    mark = monogram(mark_size, stroke, accent_stroke)
    ring = orbital_ring(mark_size, max(3, stroke // 5), 34)
    mark = Image.alpha_composite(mark, ring)
    mark = mark.rotate(-6, resample=Image.BICUBIC, expand=False)

    offset = (
        int(width * 0.755) - mark_size // 2,
        int(height * 0.50) - mark_size // 2,
    )
    shadow = mark.filter(ImageFilter.GaussianBlur(18))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), Image.new("RGBA", canvas.size, (0, 0, 0, 0)))
    canvas.alpha_composite(shadow, dest=offset)
    canvas.alpha_composite(mark, dest=offset)

    # A single hairline horizon, barely there, to anchor the composition.
    hair = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(hair)
    hdraw.line(
        [(0, int(height * 0.795)), (width, int(height * 0.795))],
        fill=(255, 255, 255, 10), width=1,
    )
    canvas = Image.alpha_composite(canvas, hair)
    return canvas.convert("RGB")


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    base = compose(BASE_W, BASE_H)
    base.save(os.path.join(out_dir, "armos-gen-4k.png"), optimize=True)

    for name, width in (("armos-gen-1080p.png", 1920), ("armos-gen-1600p.png", 2560)):
        height = round(BASE_H * width / BASE_W)
        base.resize((width, height), Image.LANCZOS).save(
            os.path.join(out_dir, name), optimize=True
        )
    print("written to", out_dir)


if __name__ == "__main__":
    main()
