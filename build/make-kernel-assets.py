#!/usr/bin/env python3
"""Generate ARMOS kernel branding assets from the prepared kernel tree.

- armos-branding.patch: prints an ARMOS banner during early boot.
- logo_linux_clut224.ppm: 80x80, <=224 colours, replaces the Linux boot logo.
"""

import difflib
import os
import sys

from PIL import Image, ImageDraw

KERNEL = os.environ.get(
    "KERNEL_DIR", "/home/ghost/armos-kernel-work/linux-6.18"
)
FILES = sys.argv[2] if len(sys.argv) > 2 else "overlay/sys-kernel/armos-kernel/files"
os.makedirs(FILES, exist_ok=True)

# --- boot banner patch -----------------------------------------------------
main_c = os.path.join(KERNEL, "init", "main.c")
with open(main_c, "r", encoding="utf-8") as fh:
    original = fh.readlines()

needle = '\tpr_notice("%s", linux_banner);\n'
if needle not in original:
    raise SystemExit("could not find linux_banner line in init/main.c")
patched = original.copy()
patched.insert(
    patched.index(needle) + 1,
    '\tpr_notice("ARMOS 1.0 GEN: custom kernel\\n");\n',
)
diff = difflib.unified_diff(
    original, patched, fromfile="a/init/main.c", tofile="b/init/main.c", n=3
)
with open(os.path.join(FILES, "armos-branding.patch"), "w", encoding="utf-8") as fh:
    fh.writelines(diff)

# --- boot logo -------------------------------------------------------------
size = 80
img = Image.new("RGB", (size, size), (0, 0, 0))
draw = ImageDraw.Draw(img)
ink = (230, 234, 240)
accent = (76, 141, 255)
cyan = (76, 194, 255)
# A monogram
draw.line([(12, 68), (40, 12), (68, 68)], fill=ink, width=7, joint="curve")
draw.line([(24, 48), (56, 48)], fill=accent, width=5)
# orbital hint
draw.arc([8, 30, 72, 46], start=200, end=350, fill=cyan, width=2)

img = img.quantize(colors=224, method=Image.Quantize.MEDIANCUT).convert("RGB")
palette = img.getcolors(maxcolors=4096)
if palette is None or len(palette) > 224:
    raise SystemExit("too many colours in boot logo")

ppm = os.path.join(FILES, "logo_linux_clut224.ppm")
with open(ppm, "w", encoding="ascii") as fh:
    fh.write("P3\n# ARMOS 1.0 GEN boot logo (224 colours)\n80 80\n255\n")
    pixels = list(img.getdata())
    for i, (r, g, b) in enumerate(pixels):
        fh.write(f"{r:3d} {g:3d} {b:3d}")
        fh.write("\n" if (i + 1) % 8 == 0 else "  ")

print(f"wrote {FILES}/armos-branding.patch ({len(palette)} palette entries)")
print(f"wrote {ppm}")
