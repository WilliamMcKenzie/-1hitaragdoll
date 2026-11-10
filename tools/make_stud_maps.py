"""Generate the PBR stud maps for the AssetKit stud MaterialVariant.

One 1024x1024 tile = 4x4 studs (StudsPerTile = 4). Each stud is a raised,
bevelled rounded square, so the engine's lighting gives a bright rim on the
sun side and a dark L on the far side, and both fade in shadow.
Writes assets/studs/stud_color.png, stud_normal.png, stud_roughness.png.
"""
import numpy as np
from PIL import Image, ImageFilter

N = 1024
STUDS = 4
cell = N // STUDS
y, x = np.mgrid[0:cell, 0:cell].astype(np.float32) + 0.5
u, v = x / cell - 0.5, y / cell - 0.5            # -0.5..0.5 inside one stud cell
half, radius, bevel = 0.30, 0.06, 0.07            # stud half-size, corner radius, bevel width
# signed distance to a rounded square
qx, qy = np.abs(u) - (half - radius), np.abs(v) - (half - radius)
d = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - radius
h = np.clip(-d / bevel, 0, 1)                     # 0 outside, ramps up over the bevel, 1 on top
h = h * h * (3 - 2 * h)                           # smooth the bevel
# faint seam lines between studs, like the reference grid of tiles
edge = np.minimum(np.minimum(x, cell - x), np.minimum(y, cell - y))
groove = np.clip(1 - edge / 3.0, 0, 1) * 0.15
height_cell = h - groove
height = np.tile(height_cell, (STUDS, STUDS))

strength = 5.0
gy, gx = np.gradient(height * strength * cell / 64.0)
nx, ny, nz = -gx, gy, np.ones_like(gx)            # OpenGL-style (+Y up), which Roblox uses
l = np.sqrt(nx * nx + ny * ny + nz * nz)
normal = np.stack([nx / l, ny / l, nz / l], -1)
Image.fromarray(((normal * 0.5 + 0.5) * 255).astype(np.uint8)).save("assets/studs/stud_normal.png")

# colour: white with soft ambient occlusion in the gaps around each stud
ao = 1 - 0.18 * np.clip(1 - h * 3, 0, 1) - 0.10 * (groove / 0.15)
ao_img = Image.fromarray((np.tile(ao, (STUDS, STUDS)) * 255).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))
Image.merge("RGB", [ao_img] * 3).save("assets/studs/stud_color.png")

# matte: high roughness everywhere
Image.fromarray(np.full((N, N), 235, np.uint8)).save("assets/studs/stud_roughness.png")
print("wrote assets/studs/stud_{color,normal,roughness}.png")
