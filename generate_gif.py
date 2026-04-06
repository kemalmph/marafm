import math
import random
try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Pillow not installed")
    exit(1)

width, height = 400, 400
frames = []
for f in range(10):
    img = Image.new('RGB', (width, height), color=(20, 20, 20))
    draw = ImageDraw.Draw(img)
    # Draw some retro neon lines moving
    offset = f * 10
    
    # CRT scanline effect
    for y in range(0, height, 4):
        draw.line([(0, (y + offset) % height), (width, (y + offset) % height)], fill=(40, 255, 180, 50), width=1)
        
    for x in range(0, width, 20):
        draw.line([(x, 0), (x, height)], fill=(40, 40, 40), width=1)

    # Some randomized static
    for _ in range(300):
        rx = random.randint(0, width)
        ry = random.randint(0, height)
        draw.point((rx, ry), fill=(255, 100, 100))

    # A central glowing circle that pulses
    radius = 80 + math.sin(f * math.pi / 5) * 10
    draw.ellipse([(width/2 - radius, height/2 - radius), (width/2 + radius, height/2 + radius)], outline=(255, 150, 0), width=3)
    
    frames.append(img)

import os
if not os.path.exists("assets"):
    os.makedirs("assets")

# Save as GIF
frames[0].save('assets/default_artwork.gif', format='GIF',
               append_images=frames[1:],
               save_all=True,
               duration=100, loop=0)
print("GIF generated successfully at assets/default_artwork.gif")
