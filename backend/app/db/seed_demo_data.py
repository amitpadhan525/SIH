"""
Seed realistic Indian handicraft demo data for SIH Problem Statement 90.
Populates realistic handicraft catalog, artisan profiles, and sample buyer inquiries.
"""
from decimal import Decimal
from sqlalchemy.orm import Session
from backend.app.db.session import SessionLocal
from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.inquiry import Inquiry


DEMO_PRODUCTS = [
    {
        "name": "Sambalpuri Double Ikat Silk Saree",
        "category": "Textiles",
        "material": "Pure Mulberry Silk & Organic Cotton",
        "price": Decimal("4800.00"),
        "description": "Handwoven Sambalpuri double ikat saree featuring traditional shankha, chakra, and floral motifs. Handcrafted by master weavers on a traditional pit loom in Bargarh, Odisha over 18 days.",
        "status": "published",
    },
    {
        "name": "Bastar Dokra Brass Tribal Lamp",
        "category": "Metalwork",
        "material": "Solid Brass & Bell Metal",
        "price": Decimal("1850.00"),
        "description": "Authentic Dokra tribal oil lamp handcrafted using the 4,000-year-old lost-wax casting technique. Features rustic antique gold finish and geometric tribal engravings from Bastar.",
        "status": "published",
    },
    {
        "name": "Terracotta Embossed Water Matka & Showpiece",
        "category": "Pottery",
        "material": "Natural Fired Terracotta Clay",
        "price": Decimal("650.00"),
        "description": "Traditional wheel-thrown terracotta pot with embossed floral patterns and natural porous cooling properties. Handcrafted using local clay and wood-kiln fired.",
        "status": "published",
    },
    {
        "name": "Mithila Madhubani Kohbar Folk Painting",
        "category": "Paintings",
        "material": "Handmade Cotton Paper & Natural Dyes",
        "price": Decimal("2400.00"),
        "description": "Authentic Madhubani painting depicting nature, sun, and prosperity. Hand-painted with fine bamboo twigs and natural mineral colors by women artisans in Mithila, Bihar.",
        "status": "published",
    },
    {
        "name": "Assam Golden Bamboo Storage Basket Set",
        "category": "Woodwork",
        "material": "Seasoned Golden Bamboo & Cane",
        "price": Decimal("1200.00"),
        "description": "Set of 3 hand-woven eco-friendly multipurpose storage baskets made from seasoned Assam bamboo. Lightweight, sturdy, and treated for long-lasting durability.",
        "status": "published",
    },
    {
        "name": "Tribal Dokra Brass Choker & Earrings",
        "category": "Jewelry",
        "material": "Lost-Wax Brass & Black Cotton Thread",
        "price": Decimal("950.00"),
        "description": "Rustic ethnic jewelry set with lost-wax cast bell beads on hand-spun adjustable cord. Inspired by traditional central Indian tribal ornamentation.",
        "status": "published",
    },
]

DEMO_INQUIRIES = [
    {
        "buyer_name": "FabIndia Sourcing Team (Rajesh Kumar)",
        "buyer_email": "sourcing@fabindia.com",
        "buyer_phone": "+919811223344",
        "buyer_type": "b2b_wholesale",
        "quantity": 50,
        "target_price": Decimal("4200.00"),
        "message": "Interested in bulk procurement of 50 Sambalpuri Ikat sarees for our upcoming Festive Autumn collection. Can you supply by next month?",
        "status": "pending",
    },
    {
        "buyer_name": "Priya Sharma (Retail Buyer)",
        "buyer_email": "priya.sharma@gmail.com",
        "buyer_phone": "+919712345678",
        "buyer_type": "retail",
        "quantity": 2,
        "target_price": Decimal("1850.00"),
        "message": "Beautiful Dokra lamp! Would love to order 2 pieces for Diwali gifting. Do you provide custom gift packaging?",
        "status": "pending",
    },
]


def ensure_default_artisan(db: Session = None):
    should_close = False
    if db is None:
        db = SessionLocal()
        should_close = True
    try:
        artisan_user = db.get(User, 1)
        if not artisan_user:
            artisan_user = User(
                id=1,
                name="Sunita Devi",
                phone="+919876543210",
                role="artisan",
                language="hi",
                location="Madhubani, Bihar",
            )
            db.add(artisan_user)
            db.flush()

        artisan = db.get(Artisan, 1)
        if not artisan:
            artisan = Artisan(
                id=1,
                user_id=1,
                craft_type="Traditional Indian Handicrafts",
                business_name="Sunita Craft Heritage",
            )
            db.add(artisan)
            db.commit()
    finally:
        if should_close:
            db.close()


def seed_demo_data(db: Session = None):
    should_close = False
    if db is None:
        db = SessionLocal()
        should_close = True

    try:
        # 1. Ensure Default Artisan User (id: 1)
        ensure_default_artisan(db)

        # 2. Seed realistic products if not already present
        existing_names = {p.name for p in db.query(Product).all()}
        created_products = []

        for p_data in DEMO_PRODUCTS:
            if p_data["name"] not in existing_names:
                product = Product(
                    artisan_id=1,
                    name=p_data["name"],
                    category=p_data["category"],
                    material=p_data["material"],
                    price=p_data["price"],
                    description=p_data["description"],
                    status=p_data["status"],
                )
                db.add(product)
                created_products.append(product)

        db.commit()

        # 3. Seed demo inquiries for products
        all_prods = db.query(Product).filter(Product.status == "published").all()
        if all_prods and db.query(Inquiry).count() == 0:
            for i, inq_data in enumerate(DEMO_INQUIRIES):
                target_prod = all_prods[i % len(all_prods)]
                inquiry = Inquiry(
                    product_id=target_prod.id,
                    buyer_name=inq_data["buyer_name"],
                    buyer_email=inq_data["buyer_email"],
                    buyer_phone=inq_data["buyer_phone"],
                    buyer_type=inq_data["buyer_type"],
                    quantity=inq_data["quantity"],
                    target_price=inq_data["target_price"],
                    message=inq_data["message"],
                    status=inq_data["status"],
                )
                db.add(inquiry)
            db.commit()

        print(f"Seed completed! Added {len(created_products)} realistic Indian handicraft products.")
    finally:
        if should_close:
            db.close()


if __name__ == "__main__":
    seed_demo_data()
