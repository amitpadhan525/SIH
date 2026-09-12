"""
Seed realistic Indian handicraft demo data for SIH Problem Statement 90.
Populates realistic artisan master craftsmen, diverse craft catalogs with high-res photography,
and authentic B2B/Retail buyer inquiries.
"""
from decimal import Decimal
from typing import Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from backend.app.db.session import SessionLocal
from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.product_image import ProductImage
from backend.app.models.inquiry import Inquiry


DEMO_ARTISANS = [
    {
        "user_id": 1,
        "name": "Sunita Devi",
        "phone": "+919876543210",
        "language": "hi",
        "location": "Madhubani, Bihar",
        "artisan_name": "Sunita Mithila Folk Heritage",
        "craft_category": "Paintings",
        "craft_type": "Mithila & Madhubani Folk Art",
        "state": "Bihar",
        "district": "Madhubani",
        "artisan_type": "Master Artisan & SHG Lead",
        "experience_years": 18,
        "description": "National awardee master folk painter specializing in authentic Madhubani and Mithila art on handmade cotton paper and pure raw silk using natural mineral and botanical dyes. Leading a self-help cooperative of 45 rural women artists.",
        "products": [
            {
                "name": "Mithila Madhubani Kohbar Wedding Wall Art",
                "category": "Paintings",
                "material": "Handmade Cotton Paper & Natural Botanical Dyes",
                "price": Decimal("2400.00"),
                "description": "Authentic Madhubani Kohbar painting symbolizing love, fertility, and cosmic balance. Handcrafted with fine bamboo twigs and natural mineral pigments extracted from flowers and clay by master artisan Sunita Devi.",
                "status": "published",
                "images": [
                    "/uploads/processed/madhubani_art_1.jpg",
                    "/uploads/processed/madhubani_art_2.jpg",
                ],
            },
            {
                "name": "Madhubani Tree of Life Tussar Silk Wall Hanging",
                "category": "Paintings",
                "material": "Pure Bhagalpuri Tussar Silk & Eco Pigments",
                "price": Decimal("3600.00"),
                "description": "Intricate hand-painted Tree of Life depicting peacocks, deer, and blooming flora. Hand-painted on pure handwoven Tussar silk with solid teakwood hanging dowels.",
                "status": "published",
                "images": [
                    "/uploads/processed/madhubani_art_2.jpg",
                    "/uploads/processed/madhubani_art_1.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 2,
        "name": "Ranjan Meher",
        "phone": "+919823456781",
        "language": "or",
        "location": "Bargarh, Odisha",
        "artisan_name": "Bargarh Ikat Handloom Guild",
        "craft_category": "Textiles",
        "craft_type": "Sambalpuri Double Ikat Weaving",
        "state": "Odisha",
        "district": "Bargarh",
        "artisan_type": "Traditional Pit-Loom Weaver",
        "experience_years": 22,
        "description": "5th-generation master weaver specializing in traditional Sambalpuri Bandha (double ikat) sarees and fabrics from Bargarh, Western Odisha. Renowned for flawless Shankha, Chakra, and Phula patterns.",
        "products": [
            {
                "name": "Sambalpuri Double Ikat Mulberry Silk Saree",
                "category": "Textiles",
                "material": "Pure Mulberry Silk & Organic Cotton Warp",
                "price": Decimal("4800.00"),
                "description": "GI-tagged handwoven Sambalpuri double ikat saree featuring traditional shankha, chakra, and floral motifs. Handcrafted by master weavers on a traditional pit loom in Bargarh over 18 days.",
                "status": "published",
                "images": [
                    "/uploads/processed/sambalpuri_saree_1.jpg",
                    "/uploads/processed/sambalpuri_saree_2.jpg",
                ],
            },
            {
                "name": "Handloom Sambalpuri Ikat Kurta Stole Set",
                "category": "Textiles",
                "material": "100% Mercerized Organic Handloom Cotton",
                "price": Decimal("1650.00"),
                "description": "Breathable, skin-friendly Sambalpuri tie-dye ikat fabric set with woven temple borders and matching tasseled stole for festive and ethnic occasions.",
                "status": "published",
                "images": [
                    "/uploads/processed/ikat_kurta_1.jpg",
                    "/uploads/processed/sambalpuri_saree_2.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 3,
        "name": "Mohammad Aslam",
        "phone": "+919834567892",
        "language": "hi",
        "location": "Jaipur, Rajasthan",
        "artisan_name": "Jaipur Turquoise Blue Glaze Pottery",
        "craft_category": "Pottery",
        "craft_type": "Traditional Blue Pottery & Ceramics",
        "state": "Rajasthan",
        "district": "Jaipur",
        "artisan_type": "Master Ceramic Craftsman",
        "experience_years": 16,
        "description": "Master artisan of authentic Jaipur Blue Pottery crafted using quartz stone powder, Fuller's earth, and natural cobalt blue glazes without using clay. GI tagged Rajasthani craft heritage.",
        "products": [
            {
                "name": "Jaipur Royal Turquoise Blue Pottery Vase",
                "category": "Pottery",
                "material": "Quartz Powder, Glass, Fuller's Earth & Cobalt Glaze",
                "price": Decimal("1450.00"),
                "description": "Exquisite hand-painted royal blue pottery vase with classic Persian and Rajasthani floral arabesque motifs. Impervious to water and kiln-fired with brilliant gloss finish.",
                "status": "published",
                "images": [
                    "/uploads/processed/jaipur_pottery_1.jpg",
                    "/uploads/processed/jaipur_pottery_2.jpg",
                ],
            },
            {
                "name": "Handcrafted Blue Pottery Ceramic Coasters & Trivet Set",
                "category": "Pottery",
                "material": "Glazed Quartz Ceramic & Non-Slip Cork Base",
                "price": Decimal("850.00"),
                "description": "Set of 6 heat-resistant artisan table coasters featuring vibrant floral hand-painting. High-fired for durability with natural stone luster.",
                "status": "published",
                "images": [
                    "/uploads/processed/jaipur_pottery_2.jpg",
                    "/uploads/processed/jaipur_pottery_1.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 4,
        "name": "Devi Lal Kashyap",
        "phone": "+919845678903",
        "language": "hi",
        "location": "Bastar, Chhattisgarh",
        "artisan_name": "Bastar Dokra Metal Artisans Guild",
        "craft_category": "Metalwork",
        "craft_type": "Lost-Wax Bell Metal Casting",
        "state": "Chhattisgarh",
        "district": "Bastar",
        "artisan_type": "Tribal Metal Sculptor",
        "experience_years": 20,
        "description": "Preserving the 4,000-year-old lost-wax bell metal casting technique (Cire Perdue) in the tribal heartland of Bastar. Every piece is unique, non-molded, and sculpted entirely by hand.",
        "products": [
            {
                "name": "Bastar Dokra Brass Tribal Oil Lamp (Diya)",
                "category": "Metalwork",
                "material": "Solid Brass & Bell Metal (Lost-Wax Cast)",
                "price": Decimal("1850.00"),
                "description": "Authentic Dokra tribal oil lamp handcrafted using the 4,000-year-old lost-wax casting technique. Features rustic antique gold finish and geometric tribal engravings from Bastar.",
                "status": "published",
                "images": [
                    "/uploads/processed/dokra_lamp_1.jpg",
                    "/uploads/processed/dokra_lamp_2.jpg",
                ],
            },
            {
                "name": "Dokra Lost-Wax Tribal Dancing Figurine",
                "category": "Metalwork",
                "material": "Cast Bell Metal with Antique Bronze Patina",
                "price": Decimal("2100.00"),
                "description": "Iconic tribal dancer holding musical pipes, sculpted with coiled wire texture and handcrafted in the historic Bastar folk tradition.",
                "status": "published",
                "images": [
                    "/uploads/processed/dokra_figurine_1.jpg",
                    "/uploads/processed/dokra_lamp_2.jpg",
                ],
            },
            {
                "name": "Tribal Dokra Bell Metal Choker & Earrings",
                "category": "Jewelry",
                "material": "Lost-Wax Brass Beads & Hand-Spun Cord",
                "price": Decimal("950.00"),
                "description": "Rustic ethnic jewelry set with lost-wax cast bell beads on hand-spun adjustable cord. Inspired by traditional central Indian tribal ornamentation.",
                "status": "published",
                "images": [
                    "/uploads/processed/tribal_jewelry_1.jpg",
                    "/uploads/processed/tribal_jewelry_2.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 5,
        "name": "Gopal Kumbhar",
        "phone": "+919856789014",
        "language": "hi",
        "location": "Gorakhpur, Uttar Pradesh",
        "artisan_name": "Gorakhpur Heritage Terracotta Works",
        "craft_category": "Pottery",
        "craft_type": "Wheel-Thrown Clay Pottery & Sculptures",
        "state": "Uttar Pradesh",
        "district": "Gorakhpur",
        "artisan_type": "Clay Sculptor & Potter",
        "experience_years": 15,
        "description": "GI-certified Gorakhpur terracotta artisan creating porous natural water pots, temple bells, and decorative clay sculptures with intricate hand-embossing and wood-fired terracotta warmth.",
        "products": [
            {
                "name": "Terracotta Embossed Water Matka & Showpiece",
                "category": "Pottery",
                "material": "Natural Porous Fired Terracotta Clay",
                "price": Decimal("650.00"),
                "description": "Traditional wheel-thrown terracotta pot with embossed floral patterns and natural porous cooling properties. Handcrafted using local clay and wood-kiln fired.",
                "status": "published",
                "images": [
                    "/uploads/processed/terracotta_pot_1.jpg",
                    "/uploads/processed/terracotta_pot_2.jpg",
                ],
            },
            {
                "name": "Traditional Terracotta Kulhad Chai Cups (Set of 6)",
                "category": "Pottery",
                "material": "Natural Organic Red Terracotta Clay",
                "price": Decimal("420.00"),
                "description": "Authentic earthen kulhad tea cups that lend an authentic earthy aroma to hot beverages. 100% biodegradable, lead-free, and heat-retaining.",
                "status": "published",
                "images": [
                    "/uploads/processed/terracotta_kulhad_1.jpg",
                    "/uploads/processed/terracotta_pot_1.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 6,
        "name": "Bashir Ahmed Mir",
        "phone": "+919878901236",
        "language": "ur",
        "location": "Srinagar, Jammu and Kashmir",
        "artisan_name": "Kashmir Heritage Pashmina Guild",
        "craft_category": "Textiles",
        "craft_type": "Pashmina & Sozni Needlework",
        "state": "Jammu and Kashmir",
        "district": "Srinagar",
        "artisan_type": "Master Pashmina Weaver",
        "experience_years": 25,
        "description": "Master artisan weaving ultra-fine Changthangi cashmere Pashmina on traditional wooden looms in old Srinagar, adorned with intricate needle-drawn Sozni floral embroidery.",
        "products": [
            {
                "name": "Handwoven Kashmiri Pashmina Sozni Embroidered Shawl",
                "category": "Textiles",
                "material": "100% Pure Changthangi Cashmere Pashmina Wool",
                "price": Decimal("12500.00"),
                "description": "Luxurious featherweight Pashmina shawl hand-embroidered with traditional Kashmiri paisley (badam) and chinar leaf motifs. Takes over 45 days of meticulous fine needlecraft.",
                "status": "published",
                "images": [
                    "/uploads/processed/pashmina_shawl_1.jpg",
                    "/uploads/processed/pashmina_shawl_2.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 7,
        "name": "Pranab Borah",
        "phone": "+919890123458",
        "language": "as",
        "location": "Majuli, Assam",
        "artisan_name": "Majuli Eco Cane & Bamboo Craft",
        "craft_category": "Woodwork",
        "craft_type": "Eco-Friendly Bamboo & Cane Craft",
        "state": "Assam",
        "district": "Majuli",
        "artisan_type": "Bamboo Craftsman & SHG Trainer",
        "experience_years": 14,
        "description": "Promoting sustainable riverbank livelihood through seasoned golden bamboo weaving, producing eco-friendly storage baskets, lampshades, and modern home organizers.",
        "products": [
            {
                "name": "Assam Golden Bamboo Storage Basket Set (3 Pcs)",
                "category": "Woodwork",
                "material": "Seasoned Golden Bamboo & Natural Cane Weave",
                "price": Decimal("1200.00"),
                "description": "Set of 3 hand-woven eco-friendly multipurpose storage baskets made from seasoned Assam bamboo. Lightweight, sturdy, fungus-treated, and long-lasting.",
                "status": "published",
                "images": [
                    "/uploads/processed/bamboo_craft_1.jpg",
                    "/uploads/processed/bamboo_craft_2.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 8,
        "name": "Kailash Chand Verma",
        "phone": "+919811234569",
        "language": "hi",
        "location": "Moradabad, Uttar Pradesh",
        "artisan_name": "Moradabad Royal Brass Artisans",
        "craft_category": "Metalwork",
        "craft_type": "Hand-Engraved Brass Metalwork",
        "state": "Uttar Pradesh",
        "district": "Moradabad",
        "artisan_type": "Master Metal Engraver",
        "experience_years": 21,
        "description": "Master brass engraver from the Brass City of Moradabad, renowned for fine hand-chiseling, floral embossing, and royal brass urlis and festive home decor.",
        "products": [
            {
                "name": "Moradabad Hand-Engraved Antique Brass Urli Bowl",
                "category": "Metalwork",
                "material": "Heavy Cast Solid Brass with Gold Lacquer Finish",
                "price": Decimal("2800.00"),
                "description": "Traditional floating flower and diya urli bowl hand-chiseled with intricate floral filigree borders. Perfect for grand entrance and festive home decor.",
                "status": "published",
                "images": [
                    "/uploads/processed/brass_urli_1.jpg",
                    "/uploads/processed/brass_urli_2.jpg",
                ],
            },
        ],
    },
    {
        "user_id": 9,
        "name": "Meenakshi Sundaram",
        "phone": "+919889012347",
        "language": "ta",
        "location": "Thanjavur, Tamil Nadu",
        "artisan_name": "Thanjavur Sacred Gold Foil Studio",
        "craft_category": "Paintings",
        "craft_type": "Tanjore 22K Gold Foil Painting",
        "state": "Tamil Nadu",
        "district": "Thanjavur",
        "artisan_type": "Classical Temple Artist",
        "experience_years": 19,
        "description": "Classical South Indian temple artist creating museum-quality Tanjore paintings on seasoned teakwood panels with genuine 22-karat gold foil and semi-precious stones.",
        "products": [
            {
                "name": "Tanjore 22K Gold Foil Balaji Wooden Panel Painting",
                "category": "Paintings",
                "material": "Seasoned Teakwood, 22K Gold Foil & Semi-Precious Stones",
                "price": Decimal("8500.00"),
                "description": "Handcrafted sacred Tanjore painting of Lord Venkateswara with relief gesso work, genuine 22-karat gold foil embossing, and vibrant mineral stone embellishments.",
                "status": "published",
                "images": [
                    "/uploads/processed/tanjore_painting_1.jpg",
                    "/uploads/processed/tanjore_painting_1.jpg",
                ],
            },
        ],
    },
]

DEMO_INQUIRIES = [
    {
        "buyer_name": "FabIndia Sourcing Team (Rajesh Kumar)",
        "buyer_email": "sourcing.festive@fabindia.com",
        "buyer_phone": "+919811223344",
        "buyer_type": "b2b_wholesale",
        "quantity": 50,
        "target_price": Decimal("4200.00"),
        "message": "Namaste! We are looking to procure 50 units of Sambalpuri Double Ikat Mulberry Silk Sarees for our upcoming Festive Autumn collection. Could you confirm delivery timeline and bulk packaging options?",
        "status": "pending",
        "product_match": "Sambalpuri",
    },
    {
        "buyer_name": "Tribes India / TRIFED Regional Officer (Anjali Verma)",
        "buyer_email": "procurement@tribesindia.gov.in",
        "buyer_phone": "+919820011223",
        "buyer_type": "b2b_wholesale",
        "quantity": 80,
        "target_price": Decimal("1600.00"),
        "message": "Interested in bulk order of Bastar Dokra Brass Lamps for the National Tribal Craft Mela in New Delhi. Please share GST invoice capability and lead time.",
        "status": "pending",
        "product_match": "Dokra",
    },
    {
        "buyer_name": "The Bombay Store (Vikramaditya Seth)",
        "buyer_email": "vikram@thebombaystore.com",
        "buyer_phone": "+919833445566",
        "buyer_type": "b2b_wholesale",
        "quantity": 30,
        "target_price": Decimal("1250.00"),
        "message": "We would love to feature your Jaipur Turquoise Blue Pottery Vases in our flagship Mumbai and Bengaluru lifestyle stores. Are custom gift box packaging available?",
        "status": "pending",
        "product_match": "Jaipur",
    },
    {
        "buyer_name": "Priya Sharma (Interior Designer & Retail Buyer, Bengaluru)",
        "buyer_email": "priya.sharma.design@gmail.com",
        "buyer_phone": "+919712345678",
        "buyer_type": "retail",
        "quantity": 2,
        "target_price": Decimal("2400.00"),
        "message": "Beautiful Mithila Madhubani painting! I would love to order 2 pieces for a heritage villa interior project in Indiranagar, Bengaluru. Can you provide custom teakwood frames?",
        "status": "pending",
        "product_match": "Madhubani",
    },
    {
        "buyer_name": "Pepperfry Curated Indian Heritage (Sneha Kulkarni)",
        "buyer_email": "curation@pepperfry.com",
        "buyer_phone": "+919867001122",
        "buyer_type": "b2b_wholesale",
        "quantity": 25,
        "target_price": Decimal("2500.00"),
        "message": "Hi Kailash ji, we are onboarding authentic Moradabad hand-engraved brassware on our luxury home decor portal. Can we place an initial trial batch of 25 brass urlis?",
        "status": "pending",
        "product_match": "Moradabad",
    },
    {
        "buyer_name": "Dr. Arvind Swaminathan (Chennai)",
        "buyer_email": "dr.arvind.swami@apollo.org",
        "buyer_phone": "+919840112233",
        "buyer_type": "retail",
        "quantity": 1,
        "target_price": Decimal("8500.00"),
        "message": "Vandanam. Interested in purchasing the Tanjore Balaji painting for our newly built pooja mandir. Does it come with a certificate of gold foil authenticity?",
        "status": "pending",
        "product_match": "Tanjore",
    },
    {
        "buyer_name": "Good Earth Sustainable Living (Ayesha Merchant)",
        "buyer_email": "sourcing@goodearth.in",
        "buyer_phone": "+919821998877",
        "buyer_type": "b2b_wholesale",
        "quantity": 60,
        "target_price": Decimal("1000.00"),
        "message": "Greetings! We love your Assam Golden Bamboo storage baskets. We would like to place an order of 60 sets for our eco-conscious living line across India.",
        "status": "pending",
        "product_match": "Bamboo",
    },
]


def ensure_default_artisan(db: Session = None):
    """Ensures at least the primary demo user (id=1 Sunita Devi) exists."""
    should_close = False
    if db is None:
        db = SessionLocal()
        should_close = True
    try:
        user = db.get(User, 1)
        if not user:
            user = User(
                id=1,
                name="Sunita Devi",
                phone="+919876543210",
                role="artisan",
                language="hi",
                location="Madhubani, Bihar",
            )
            db.add(user)
            db.flush()
        else:
            user.name = "Sunita Devi"
            user.phone = "+919876543210"
            user.role = "artisan"
            user.language = "hi"
            user.location = "Madhubani, Bihar"

        artisan = db.get(Artisan, 1)
        if not artisan:
            artisan = Artisan(
                id=1,
                user_id=1,
                craft_type="Mithila & Madhubani Folk Art",
                craft_category="Paintings",
                artisan_name="Sunita Mithila Folk Heritage",
                state="Bihar",
                district="Madhubani",
                preferred_language="hi",
                artisan_type="Master Artisan & SHG Lead",
                experience_years=18,
                description="National awardee master folk painter specializing in authentic Madhubani and Mithila art on handmade cotton paper and pure raw silk using natural mineral and botanical dyes.",
                is_profile_complete=True,
            )
            db.add(artisan)
        else:
            artisan.artisan_name = "Sunita Mithila Folk Heritage"
            artisan.craft_category = "Paintings"
            artisan.craft_type = "Mithila & Madhubani Folk Art"
            artisan.state = "Bihar"
            artisan.district = "Madhubani"
            artisan.preferred_language = "hi"
            artisan.artisan_type = "Master Artisan & SHG Lead"
            artisan.experience_years = 18
            artisan.is_profile_complete = True

        db.commit()
    finally:
        if should_close:
            db.close()


def seed_demo_data(db: Session = None, clean: bool = False):
    """
    Seeds comprehensive real Indian master artisans, authentic products with photos,
    and genuine buyer inquiries.
    """
    should_close = False
    if db is None:
        db = SessionLocal()
        should_close = True

    try:
        if clean:
            print("Cleaning existing demo tables...")
            db.query(Inquiry).delete()
            db.query(ProductImage).delete()
            db.query(Product).delete()
            db.query(Artisan).delete()
            db.query(User).delete()
            db.commit()

        # 1. Create/Update All Master Artisan Users
        for a_data in DEMO_ARTISANS:
            user = db.execute(select(User).where(User.phone == a_data["phone"])).scalar_one_or_none()
            if not user:
                user = User(
                    name=a_data["name"],
                    phone=a_data["phone"],
                    role="artisan",
                    language=a_data["language"],
                    location=a_data["location"],
                )
                db.add(user)
                db.flush()
            else:
                user.name = a_data["name"]
                user.language = a_data["language"]
                user.location = a_data["location"]
                user.role = "artisan"

            artisan = db.execute(select(Artisan).where(Artisan.user_id == user.id)).scalar_one_or_none()
            if not artisan:
                artisan = Artisan(
                    user_id=user.id,
                    craft_type=a_data["craft_type"],
                    craft_category=a_data["craft_category"],
                    artisan_name=a_data["artisan_name"],
                    state=a_data["state"],
                    district=a_data["district"],
                    preferred_language=a_data["language"],
                    artisan_type=a_data["artisan_type"],
                    experience_years=a_data["experience_years"],
                    description=a_data["description"],
                    is_profile_complete=True,
                )
                db.add(artisan)
                db.flush()
            else:
                artisan.craft_type = a_data["craft_type"]
                artisan.craft_category = a_data["craft_category"]
                artisan.artisan_name = a_data["artisan_name"]
                artisan.state = a_data["state"]
                artisan.district = a_data["district"]
                artisan.preferred_language = a_data["language"]
                artisan.artisan_type = a_data["artisan_type"]
                artisan.experience_years = a_data["experience_years"]
                artisan.description = a_data["description"]
                artisan.is_profile_complete = True

            # Seed Products for this Artisan
            for p_info in a_data["products"]:
                prod = db.execute(
                    select(Product).where(
                        Product.artisan_id == artisan.id,
                        Product.name == p_info["name"]
                    )
                ).scalar_one_or_none()

                if not prod:
                    prod = Product(
                        artisan_id=artisan.id,
                        name=p_info["name"],
                        category=p_info["category"],
                        material=p_info["material"],
                        price=p_info["price"],
                        description=p_info["description"],
                        status=p_info["status"],
                    )
                    db.add(prod)
                    db.flush()
                else:
                    prod.category = p_info["category"]
                    prod.material = p_info["material"]
                    prod.price = p_info["price"]
                    prod.description = p_info["description"]
                    prod.status = p_info["status"]

                # Ensure Product Images
                existing_imgs = {img.processed_url for img in prod.images}
                for img_url in p_info["images"]:
                    if img_url not in existing_imgs:
                        p_img = ProductImage(
                            product_id=prod.id,
                            original_url=img_url,
                            processed_url=img_url,
                        )
                        db.add(p_img)

        db.commit()

        # 2. Seed Demo Inquiries matched by keyword
        all_products = db.query(Product).filter(Product.status == "published").all()
        for inq in DEMO_INQUIRIES:
            # Find matching product
            matched_prod = None
            for p in all_products:
                if inq["product_match"].lower() in p.name.lower() or inq["product_match"].lower() in p.category.lower():
                    matched_prod = p
                    break
            if not matched_prod and all_products:
                matched_prod = all_products[0]

            if matched_prod:
                existing_inq = db.execute(
                    select(Inquiry).where(
                        Inquiry.product_id == matched_prod.id,
                        Inquiry.buyer_email == inq["buyer_email"]
                    )
                ).scalar_one_or_none()

                if not existing_inq:
                    new_inquiry = Inquiry(
                        product_id=matched_prod.id,
                        buyer_name=inq["buyer_name"],
                        buyer_email=inq["buyer_email"],
                        buyer_phone=inq["buyer_phone"],
                        buyer_type=inq["buyer_type"],
                        quantity=inq["quantity"],
                        target_price=inq["target_price"],
                        message=inq["message"],
                        status=inq["status"],
                    )
                    db.add(new_inquiry)

        db.commit()

        user_cnt = db.query(User).count()
        prod_cnt = db.query(Product).count()
        inq_cnt = db.query(Inquiry).count()
        print(f"✨ Successfully seeded real Indian craft data: {user_cnt} Users/Artisans, {prod_cnt} Products, {inq_cnt} Buyer Inquiries.")

    finally:
        if should_close:
            db.close()


if __name__ == "__main__":
    seed_demo_data()
