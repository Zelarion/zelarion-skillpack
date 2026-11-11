"""Gold-thread banner art for the Drezivo workspace, rendered twice from one seed: the same
composition on night (dark theme) and on paper (light theme). Drawn here, nothing licensed."""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

W, H, SS = 1800, 640, 2  # supersampled for clean hairlines
SEED = 1702

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def ground(theme):
    img = Image.new('RGB', (W, H))
    px = img.load()
    if theme == 'dark':
        c0, c1, glow = (27, 21, 17), (10, 8, 6), (70, 52, 32)
    else:
        c0, c1, glow = (251, 248, 243), (236, 226, 210), (244, 228, 196)
    gx, gy = W * 0.72, H * 0.45
    for y in range(H):
        for x in range(W):
            t = min(1.0, math.hypot((x - gx) / W, (y - gy) / H) * 1.35)
            base = lerp(c0, c1, (x / W) * 0.35 + (y / H) * 0.25)
            px[x, y] = lerp(glow, base, t ** 0.8)
    return img

def scene():
    rnd = random.Random(SEED)
    nodes = []
    # Threads gather to the right; the left stays quiet for the headline.
    for _ in range(46):
        x = W * (0.38 + 0.62 * (rnd.random() ** 0.7))
        y = H * (0.5 + (rnd.random() - 0.5) * (0.35 + 0.65 * (x / W)))
        nodes.append((x, y, rnd.uniform(1.6, 5.5)))
    edges = set()
    for i, (x, y, _) in enumerate(nodes):
        near = sorted(range(len(nodes)), key=lambda j: math.hypot(nodes[j][0] - x, nodes[j][1] - y))[1:5]
        for j in near:
            edges.add(tuple(sorted((i, j))))
    # One long sweeping thread, like a tape measure across the frame.
    sweep = [(W * t, H * (0.62 - 0.28 * math.sin(t * math.pi * 1.1) + 0.05 * math.sin(t * 9))) for t in [k / 120 for k in range(121)]]
    dust = [(rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(0.6, 2.4), rnd.random()) for _ in range(420)]
    bokeh = [(W * rnd.uniform(0.45, 1), rnd.uniform(0, H), rnd.uniform(10, 34), rnd.random()) for _ in range(26)]
    return nodes, sorted(edges), sweep, dust, bokeh

def render(theme, out):
    nodes, edges, sweep, dust, bokeh = scene()
    if theme == 'dark':
        line, node, spark, dustc = (212, 180, 131), (247, 227, 181), (255, 246, 225), (226, 206, 169)
    else:
        line, node, spark, dustc = (160, 122, 70), (176, 132, 74), (122, 88, 48), (160, 122, 70)
    base = ground(theme).convert('RGBA')
    layer = Image.new('RGBA', (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    fade = lambda x: max(0.0, min(1.0, (x / W - 0.3) / 0.35))
    for i, j in edges:
        (x1, y1, _), (x2, y2, _) = nodes[i], nodes[j]
        a = int((110 if theme == 'dark' else 120) * fade((x1 + x2) / 2))
        d.line([(x1 * SS, y1 * SS), (x2 * SS, y2 * SS)], fill=line + (a,), width=SS)
    d.line([(x * SS, y * SS) for x, y in sweep], fill=line + (90 if theme == 'dark' else 110,), width=2 * SS)
    for x, y, r, k in dust:
        a = int((60 + 140 * k) * (0.25 + 0.75 * fade(x)))
        d.ellipse([(x - r / 2) * SS, (y - r / 2) * SS, (x + r / 2) * SS, (y + r / 2) * SS], fill=dustc + (a,))
    layer = layer.resize((W, H), Image.LANCZOS)
    # Soft bokeh and node glow underneath the sharp lines.
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for x, y, r, k in bokeh:
        g.ellipse([x - r, y - r, x + r, y + r], fill=node + (int(28 + 40 * k),))
    for x, y, r in nodes:
        R = r * 5
        g.ellipse([x - R, y - R, x + R, y + R], fill=node + (int(70 * fade(x)) + 20,))
    glow = glow.filter(ImageFilter.GaussianBlur(9))
    sharp = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    s = ImageDraw.Draw(sharp)
    for x, y, r in nodes:
        a = int(255 * (0.35 + 0.65 * fade(x)))
        s.ellipse([x - r, y - r, x + r, y + r], fill=spark + (a,))
        if r > 4.6:  # four-point glint on the brightest knots
            for dx, dy in ((1, 0), (0, 1)):
                s.line([(x - dx * r * 3, y - dy * r * 3), (x + dx * r * 3, y + dy * r * 3)], fill=spark + (a // 2,), width=1)
    img = Image.alpha_composite(base, glow)
    img = Image.alpha_composite(img, layer)
    img = Image.alpha_composite(img, sharp)
    # Film grain against banding in the gradient.
    rnd = random.Random(SEED + 1)
    noise = Image.effect_noise((W, H), 18).convert('L')
    img = Image.blend(img.convert('RGB'), Image.merge('RGB', (noise, noise, noise)), 0.025)
    img.save(out, 'WEBP', quality=82, method=6)

for theme in ('dark', 'light'):
    render(theme, f'banner-{theme}.webp')
print('ok')
