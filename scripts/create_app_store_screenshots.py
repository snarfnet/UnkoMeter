from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "AppStoreAssets" / "screenshots"
ICON = ROOT / "UnkoMeter" / "Assets.xcassets" / "AppIcon.appiconset" / "app-icon-1024.png"

OUT.mkdir(parents=True, exist_ok=True)


def font(size, bold=False):
    candidates = [
        Path("C:/Windows/Fonts/meiryob.ttc" if bold else "C:/Windows/Fonts/meiryo.ttc"),
        Path("C:/Windows/Fonts/YuGothB.ttc" if bold else "C:/Windows/Fonts/YuGothM.ttc"),
        Path("C:/Windows/Fonts/msgothic.ttc"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def rounded(draw, xy, r, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def shadowed_card(base, xy, r, fill, shadow=(18, 28), alpha=38):
    x1, y1, x2, y2 = xy
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((x1, y1, x2, y2), radius=r, fill=(30, 35, 32, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(shadow[0]))
    base.alpha_composite(layer, (0, shadow[1]))
    ImageDraw.Draw(base).rounded_rectangle(xy, radius=r, fill=fill)


def text(draw, xy, value, size, fill=(31, 36, 33), bold=False, anchor=None, align="left"):
    draw.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor, align=align)


def fit_text(draw, box, value, size, fill, bold=False, anchor="mm"):
    x1, y1, x2, y2 = box
    current = size
    while current > 16:
        f = font(current, bold)
        bbox = draw.multiline_textbbox((0, 0), value, font=f, spacing=max(6, current // 5))
        if bbox[2] - bbox[0] <= x2 - x1 and bbox[3] - bbox[1] <= y2 - y1:
            draw.multiline_text(((x1 + x2) / 2, (y1 + y2) / 2), value, font=f, fill=fill, anchor=anchor, align="center", spacing=max(6, current // 5))
            return
        current -= 2
    draw.multiline_text(((x1 + x2) / 2, (y1 + y2) / 2), value, font=font(current, bold), fill=fill, anchor=anchor, align="center")


def background(w, h):
    img = Image.new("RGBA", (w, h), (250, 245, 230, 255))
    pix = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            r = int(250 * (1 - t) + 222 * t)
            g = int(245 * (1 - t) + 240 * t)
            b = int(230 * (1 - t) + 210 * t)
            pix[x, y] = (r, g, b, 255)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((int(w * .62), -int(w * .18), int(w * 1.16), int(w * .36)), fill=(25, 158, 125, 34))
    d.ellipse((-int(w * .24), int(h * .70), int(w * .34), int(h * 1.02)), fill=(237, 179, 51, 46))
    img.alpha_composite(layer)
    return img


def phone_frame(base, box):
    d = ImageDraw.Draw(base)
    shadowed_card(base, box, 80, (253, 251, 244, 255), shadow=(24, 32), alpha=46)
    x1, y1, x2, y2 = box
    d.rounded_rectangle((x1 + 22, y1 + 22, x2 - 22, y2 - 22), radius=62, outline=(255, 255, 255, 210), width=3)
    return (x1 + 56, y1 + 78, x2 - 56, y2 - 64)


def draw_header(d, area, eyebrow, title, subtitle, scale):
    x1, y1, x2, _ = area
    text(d, (x1, y1), eyebrow, int(20 * scale), fill=(26, 158, 125), bold=True)
    text(d, (x1, y1 + int(38 * scale)), title, int(50 * scale), bold=True)
    text(d, (x1, y1 + int(106 * scale)), subtitle, int(23 * scale), fill=(96, 97, 88))


def draw_timer_screen(base, area, scale):
    d = ImageDraw.Draw(base)
    x1, y1, x2, y2 = area
    draw_header(d, (x1, y1, x2, y2), "READY", "今日のトイレを記録", "時間、状態、メモ。あとで体調のクセが見えます。", scale)

    card = (x1, y1 + int(185 * scale), x2, y1 + int(690 * scale))
    shadowed_card(base, card, int(18 * scale), (255, 255, 255, 210))
    cx, cy = (x1 + x2) // 2, card[1] + int(235 * scale)
    r = int(150 * scale)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(226, 216, 190), width=int(22 * scale))
    d.arc((cx - r, cy - r, cx + r, cy + r), start=-90, end=84, fill=(26, 158, 125), width=int(22 * scale))
    text(d, (cx, cy - int(22 * scale)), "05:24", int(67 * scale), bold=True, anchor="mm")
    text(d, (cx, cy + int(50 * scale)), "計測中", int(22 * scale), fill=(26, 158, 125), bold=True, anchor="mm")
    text(d, (cx, card[3] - int(58 * scale)), "長く続く不調や血便がある場合は、医療機関に相談してください。", int(20 * scale), fill=(96, 97, 88), anchor="mm")

    text(d, (x1, card[3] + int(56 * scale)), "状態", int(30 * scale), bold=True)
    labels = [("快便", "いい調子", (26, 158, 125)), ("やや硬い", "水分を意識", (237, 179, 51)), ("ゆるい", "食事を確認", (219, 61, 59))]
    top = card[3] + int(105 * scale)
    gap = int(18 * scale)
    bw = (x2 - x1 - gap * 2) // 3
    for i, (a, b, c) in enumerate(labels):
        bx = x1 + i * (bw + gap)
        fill = c if i == 0 else (255, 255, 255, 205)
        rounded(d, (bx, top, bx + bw, top + int(145 * scale)), int(16 * scale), fill + ((255,) if len(fill) == 3 else ()), outline=(c[0], c[1], c[2], 60))
        text(d, (bx + bw // 2, top + int(53 * scale)), a, int(25 * scale), fill=(255, 255, 255) if i == 0 else (31, 36, 33), bold=True, anchor="mm")
        text(d, (bx + bw // 2, top + int(97 * scale)), b, int(17 * scale), fill=(255, 255, 255, 220) if i == 0 else (96, 97, 88), anchor="mm")

    btn_y = top + int(185 * scale)
    rounded(d, (x1, btn_y, x1 + (x2 - x1 - gap) // 2, btn_y + int(76 * scale)), int(15 * scale), (26, 158, 125, 255))
    rounded(d, (x1 + (x2 - x1 + gap) // 2, btn_y, x2, btn_y + int(76 * scale)), int(15 * scale), (31, 36, 33, 255))
    text(d, (x1 + (x2 - x1 - gap) // 4, btn_y + int(38 * scale)), "開始", int(27 * scale), fill=(255, 255, 255), bold=True, anchor="mm")
    text(d, (x1 + (x2 - x1 + gap) * 3 // 4, btn_y + int(38 * scale)), "保存", int(27 * scale), fill=(255, 255, 255), bold=True, anchor="mm")


def draw_stats_screen(base, area, scale):
    d = ImageDraw.Draw(base)
    x1, y1, x2, y2 = area
    draw_header(d, (x1, y1, x2, y2), "BODY LOG", "今月の調子", "記録が増えるほど、食事と体調のつながりが見えます。", scale)
    cards = [
        ("総記録", "24", "回", (26, 158, 125)),
        ("平均時間", "4分12秒", "", (107, 69, 46)),
        ("快便率", "83", "%", (26, 158, 125)),
        ("今月ゆるめ", "2", "回", (219, 61, 59)),
    ]
    top = y1 + int(180 * scale)
    gap = int(18 * scale)
    cw = (x2 - x1 - gap) // 2
    ch = int(180 * scale)
    for i, (title, value, unit, color) in enumerate(cards):
        bx = x1 + (i % 2) * (cw + gap)
        by = top + (i // 2) * (ch + gap)
        shadowed_card(base, (bx, by, bx + cw, by + ch), int(16 * scale), (255, 255, 255, 210))
        text(d, (bx + int(28 * scale), by + int(42 * scale)), title, int(21 * scale), fill=(96, 97, 88), bold=True)
        text(d, (bx + int(28 * scale), by + int(112 * scale)), value, int(48 * scale) if len(value) <= 3 else int(36 * scale), bold=True)
        if unit:
            text(d, (bx + cw - int(38 * scale), by + int(122 * scale)), unit, int(20 * scale), fill=(96, 97, 88), bold=True, anchor="ra")

    panel = (x1, top + int(410 * scale), x2, top + int(800 * scale))
    shadowed_card(base, panel, int(16 * scale), (255, 255, 255, 214))
    text(d, (panel[0] + int(28 * scale), panel[1] + int(42 * scale)), "状態別", int(30 * scale), bold=True)
    rows = [("快便", 17, (26, 158, 125)), ("やや硬い", 5, (237, 179, 51)), ("かなり硬い", 2, (214, 110, 46)), ("ゆるい", 2, (219, 61, 59)), ("色が気になる", 1, (115, 77, 158))]
    maxv = 17
    for i, (name, val, color) in enumerate(rows):
        yy = panel[1] + int((100 + i * 52) * scale)
        text(d, (panel[0] + int(30 * scale), yy), name, int(21 * scale), bold=True)
        bar_x = panel[0] + int(190 * scale)
        bar_w = panel[2] - bar_x - int(80 * scale)
        rounded(d, (bar_x, yy + int(7 * scale), bar_x + bar_w, yy + int(21 * scale)), int(8 * scale), (226, 216, 190, 255))
        rounded(d, (bar_x, yy + int(7 * scale), bar_x + int(bar_w * val / maxv), yy + int(21 * scale)), int(8 * scale), color + (255,))
        text(d, (panel[2] - int(32 * scale), yy), str(val), int(22 * scale), bold=True, anchor="ra")


def draw_notes_screen(base, area, scale):
    d = ImageDraw.Draw(base)
    x1, y1, x2, y2 = area
    draw_header(d, (x1, y1, x2, y2), "FOOD INSIGHT", "食事メモも一緒に", "気になる日の食べ物を残すと、あとで見返しやすくなります。", scale)
    panel = (x1, y1 + int(190 * scale), x2, y1 + int(445 * scale))
    shadowed_card(base, panel, int(16 * scale), (255, 255, 255, 214))
    text(d, (panel[0] + int(28 * scale), panel[1] + int(45 * scale)), "気になる記録によく出る言葉", int(22 * scale), fill=(96, 97, 88), bold=True)
    text(d, (panel[0] + int(28 * scale), panel[1] + int(127 * scale)), "ラーメン", int(58 * scale), fill=(107, 69, 46), bold=True)
    text(d, (panel[0] + int(28 * scale), panel[1] + int(205 * scale)), "メモが増えるほど、自分の体調パターンが見えてきます。", int(22 * scale), fill=(96, 97, 88))

    records = [
        ("快便", "今日 08:12", "ヨーグルト、よく眠れた", "3分42秒", (26, 158, 125)),
        ("ゆるい", "昨日 23:40", "ラーメン、辛い", "5分10秒", (219, 61, 59)),
        ("やや硬い", "5/16 07:55", "水分少なめ", "7分03秒", (237, 179, 51)),
    ]
    text(d, (x1, panel[3] + int(70 * scale)), "最近の記録", int(30 * scale), bold=True)
    top = panel[3] + int(110 * scale)
    for i, (a, b, c, dur, color) in enumerate(records):
        yy = top + i * int(135 * scale)
        shadowed_card(base, (x1, yy, x2, yy + int(104 * scale)), int(16 * scale), (255, 255, 255, 214), shadow=(12, 14), alpha=20)
        rounded(d, (x1 + int(22 * scale), yy + int(24 * scale), x1 + int(78 * scale), yy + int(80 * scale)), int(12 * scale), color + (255,))
        text(d, (x1 + int(104 * scale), yy + int(30 * scale)), a, int(24 * scale), bold=True)
        text(d, (x1 + int(205 * scale), yy + int(31 * scale)), b, int(19 * scale), fill=(96, 97, 88))
        text(d, (x1 + int(104 * scale), yy + int(66 * scale)), c, int(19 * scale), fill=(96, 97, 88))
        text(d, (x2 - int(25 * scale), yy + int(53 * scale)), dur, int(19 * scale), bold=True, anchor="ra")


def compose(width, height, title, subtitle, screen, filename, tablet=False):
    img = background(width, height)
    d = ImageDraw.Draw(img)
    top = int(height * 0.075)
    text(d, (width // 2, top), title, int(width * (0.057 if not tablet else 0.044)), fill=(31, 36, 33), bold=True, anchor="mm")
    fit_text(d, (int(width * .14), top + int(height * .045), int(width * .86), top + int(height * .115)), subtitle, int(width * (0.032 if not tablet else 0.026)), (96, 97, 88), bold=False)

    if tablet:
        frame = (int(width * .23), int(height * .25), int(width * .77), int(height * .91))
        scale = width / 1900
    else:
        frame = (int(width * .18), int(height * .24), int(width * .82), int(height * .92))
        scale = width / 1290
    area = phone_frame(img, frame)
    screen(img, area, scale)
    d = ImageDraw.Draw(img)
    tab_h = int(72 * scale)
    rounded(d, (area[0], area[3] - tab_h, area[2], area[3] - int(5 * scale)), int(8 * scale), (255, 255, 255, 210))
    text(d, (area[0] + int((area[2] - area[0]) * .32), area[3] - int(38 * scale)), "記録", int(18 * scale), fill=(26, 158, 125), bold=True, anchor="mm")
    text(d, (area[0] + int((area[2] - area[0]) * .68), area[3] - int(38 * scale)), "ふり返り", int(18 * scale), fill=(96, 97, 88), bold=True, anchor="mm")
    img.convert("RGB").save(OUT / filename, quality=95)


sets = [
    ("01-record", "トイレ時間をさっと記録", "開始して、終わったら状態を選んで保存。毎日のリズムを軽く残せます。", draw_timer_screen),
    ("02-stats", "今月の調子を見える化", "快便率、平均時間、状態別の傾向をひと目で確認できます。", draw_stats_screen),
    ("03-notes", "食事メモで原因を探す", "気になる記録に出やすい食べ物を見返して、自分のクセを探せます。", draw_notes_screen),
]

for stem, title, subtitle, screen in sets:
    compose(1290, 2796, title, subtitle, screen, f"iphone-67-{stem}.png")
    compose(2048, 2732, title, subtitle, screen, f"ipad-129-{stem}.png", tablet=True)

print(f"Created screenshots in {OUT}")
