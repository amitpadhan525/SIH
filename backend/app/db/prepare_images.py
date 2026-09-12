import os
import io
import requests
from PIL import Image, ImageDraw, ImageFont

UPLOAD_DIR = "/home/amit/github/SIH/backend/uploads"
PROC_DIR = os.path.join(UPLOAD_DIR, "processed")
ORIG_DIR = os.path.join(UPLOAD_DIR, "originals")

os.makedirs(PROC_DIR, exist_ok=True)
os.makedirs(ORIG_DIR, exist_ok=True)

# Curated high-resolution Unsplash craft photography URLs (royalty-free Unsplash public images)
CRAFT_IMAGE_SOURCES = {
    "sambalpuri_saree_1": "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1000&auto=format&fit=crop&q=80",
    "sambalpuri_saree_2": "https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=1000&auto=format&fit=crop&q=80",
    "dokra_lamp_1": "https://images.unsplash.com/photo-1596178060671-7a80dc8059ea?w=1000&auto=format&fit=crop&q=80",
    "dokra_lamp_2": "https://images.unsplash.com/photo-1606744837616-56c9a5c6a6eb?w=1000&auto=format&fit=crop&q=80",
    "terracotta_pot_1": "https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=1000&auto=format&fit=crop&q=80",
    "terracotta_pot_2": "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=1000&auto=format&fit=crop&q=80",
    "madhubani_art_1": "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=1000&auto=format&fit=crop&q=80",
    "madhubani_art_2": "https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?w=1000&auto=format&fit=crop&q=80",
    "jaipur_pottery_1": "https://images.unsplash.com/photo-1615486511484-92e172cc4fe0?w=1000&auto=format&fit=crop&q=80",
    "jaipur_pottery_2": "https://images.unsplash.com/photo-1581783342308-f792dbdd27c5?w=1000&auto=format&fit=crop&q=80",
    "channapatna_toy_1": "https://images.unsplash.com/photo-1558060370-d644479cb6f7?w=1000&auto=format&fit=crop&q=80",
    "channapatna_toy_2": "https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=1000&auto=format&fit=crop&q=80",
    "pashmina_shawl_1": "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=1000&auto=format&fit=crop&q=80",
    "pashmina_shawl_2": "https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=1000&auto=format&fit=crop&q=80",
    "tanjore_painting_1": "https://images.unsplash.com/photo-1582561424760-0321d75e81fa?w=1000&auto=format&fit=crop&q=80",
    "bamboo_craft_1": "https://images.unsplash.com/photo-1584589167171-541ce45f1eea?w=1000&auto=format&fit=crop&q=80",
    "bamboo_craft_2": "https://images.unsplash.com/photo-1590736969955-71cc94801759?w=1000&auto=format&fit=crop&q=80",
    "brass_urli_1": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1000&auto=format&fit=crop&q=80",
    "brass_urli_2": "https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=1000&auto=format&fit=crop&q=80",
    "tribal_jewelry_1": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1000&auto=format&fit=crop&q=80",
    "tribal_jewelry_2": "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1000&auto=format&fit=crop&q=80",
    "terracotta_kulhad_1": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=1000&auto=format&fit=crop&q=80",
    "ikat_kurta_1": "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1000&auto=format&fit=crop&q=80",
    "dokra_figurine_1": "https://images.unsplash.com/photo-1544717305-2782549b5136?w=1000&auto=format&fit=crop&q=80",
}

def create_fallback_image(title, subtitle, color_theme):
    img = Image.new("RGB", (1024, 1024), color_theme[0])
    draw = ImageDraw.Draw(img)
    
    # Inner border
    draw.rectangle([40, 40, 984, 984], outline=color_theme[1], width=12)
    draw.rectangle([60, 60, 964, 964], outline=color_theme[1], width=3)
    
    # Title & Subtitle
    draw.text((512, 450), title, fill=color_theme[2], anchor="mm")
    draw.text((512, 530), subtitle, fill=color_theme[1], anchor="mm")
    draw.text((512, 600), "Handcrafted in India • Certified Artisan", fill=(100, 100, 100), anchor="mm")
    return img

print("Downloading / preparing images...")
for key, url in CRAFT_IMAGE_SOURCES.items():
    proc_path = os.path.join(PROC_DIR, f"{key}.jpg")
    orig_path = os.path.join(ORIG_DIR, f"{key}.jpg")
    
    if os.path.exists(proc_path):
        print(f"Already exists: {key}")
        continue
        
    try:
        resp = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
        if resp.status_code == 200:
            img = Image.open(io.BytesIO(resp.content)).convert("RGB")
            # Center crop to square 1024x1024
            min_dim = min(img.size)
            left = (img.width - min_dim) // 2
            top = (img.height - min_dim) // 2
            right = left + min_dim
            bottom = top + min_dim
            img_cropped = img.crop((left, top, right, bottom)).resize((1024, 1024), Image.Resampling.LANCZOS)
            
            img_cropped.save(proc_path, "JPEG", quality=90)
            img_cropped.save(orig_path, "JPEG", quality=90)
            print(f"Downloaded & saved: {key}")
            continue
    except Exception as e:
        print(f"Download failed for {key}: {e}")
        
    # Fallback if download failed
    fallback = create_fallback_image(key.replace("_", " ").title(), "Artisan Handcrafted", ((250, 245, 238), (184, 92, 56), (44, 24, 16)))
    fallback.save(proc_path, "JPEG", quality=90)
    fallback.save(orig_path, "JPEG", quality=90)
    print(f"Created fallback image for: {key}")

print("All craft images ready!")
