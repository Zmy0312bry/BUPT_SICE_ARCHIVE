import os
from datetime import datetime

from PIL import Image, ImageDraw, ImageFont

RESULT_PATH = "result"


def time_stamp(img_path, output_path):
    # 打开图片
    img = Image.open(img_path).convert("RGB")
    draw = ImageDraw.Draw(img)

    # 获取当前时间
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 设置字体（使用默认字体）
    try:
        font = ImageFont.truetype("arial.ttf", 40)
    except:
        font = ImageFont.load_default()

    # 在右下角添加水印（边距20px）
    width, height = img.size
    text_bbox = draw.textbbox((0, 0), timestamp, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    x = width - text_width - 20
    y = height - text_height - 20

    # 绘制黑色背景（提高可读性）
    draw.rectangle(
        [x - 10, y - 10, x + text_width + 10, y + text_height + 10], fill=(0, 0, 0, 128)
    )
    # 绘制白色文字
    draw.text((x, y), timestamp, fill=(255, 255, 255), font=font)

    # 保存
    img.save(output_path)


for item in os.listdir(RESULT_PATH):
    if item.endswith("png"):
        print(f"{RESULT_PATH}/{item}")
        time_stamp(f"{RESULT_PATH}/{item}", f"{RESULT_PATH}/{item}")

# time_stamp("result/载荷.png", "result/载荷.png")
