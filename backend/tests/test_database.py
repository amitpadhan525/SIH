import pytest
from decimal import Decimal
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.product_image import ProductImage
from backend.app.schemas.user import UserCreate, UserRead
from backend.app.schemas.product import ProductCreate, ProductRead


def test_create_user(db_session: Session):
    user = User(
        name="Ramesh Kumar",
        phone="+919876543210",
        role="artisan",
        language="hi",
        location="Jaipur, Rajasthan",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    assert user.id is not None
    assert user.name == "Ramesh Kumar"
    assert user.phone == "+919876543210"
    assert user.role == "artisan"
    assert user.language == "hi"
    assert user.location == "Jaipur, Rajasthan"
    assert user.created_at is not None

    # Verify Pydantic schema serialization
    user_read = UserRead.model_validate(user)
    assert user_read.id == user.id
    assert user_read.phone == "+919876543210"


def test_unique_user_phone_constraint(db_session: Session):
    user1 = User(name="User One", phone="+919999999999")
    db_session.add(user1)
    db_session.commit()

    user2 = User(name="User Two", phone="+919999999999")
    db_session.add(user2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_artisan_and_product_relationships_and_price_decimal(db_session: Session):
    # 1. Create User
    user = User(
        name="Sita Devi",
        phone="+919123456780",
        role="artisan",
        language="hi",
        location="Varanasi, UP",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    # 2. Create Artisan
    artisan = Artisan(
        user_id=user.id,
        craft_type="Banarasi Silk Weaving",
    )
    db_session.add(artisan)
    db_session.commit()
    db_session.refresh(artisan)

    assert artisan.id is not None
    assert artisan.user.name == "Sita Devi"
    assert user.artisan.craft_type == "Banarasi Silk Weaving"

    # 3. Create Product with precise Decimal monetary value
    product = Product(
        artisan_id=artisan.id,
        name="Handcrafted Pure Silk Saree",
        category="Apparel",
        description="Authentic handwoven Varanasi silk saree with gold zari border.",
        material="Pure Silk",
        price=Decimal("12499.50"),
        status="published",
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    assert product.id is not None
    assert product.artisan.user.name == "Sita Devi"
    assert product.price == Decimal("12499.50")
    assert len(artisan.products) == 1

    # 4. Create Product Image
    image1 = ProductImage(
        product_id=product.id,
        original_url="https://storage.example.com/raw/saree_front.jpg",
        processed_url="https://storage.example.com/clean/saree_front.png",
    )
    db_session.add(image1)
    db_session.commit()
    db_session.refresh(image1)

    assert image1.id is not None
    assert image1.product.name == "Handcrafted Pure Silk Saree"
    assert len(product.images) == 1

    # 5. Verify Pydantic ProductRead schema serialization with images
    db_session.refresh(product)
    product_read = ProductRead.model_validate(product)
    assert product_read.id == product.id
    assert product_read.price == Decimal("12499.50")
    assert len(product_read.images) == 1
    assert product_read.images[0].original_url == "https://storage.example.com/raw/saree_front.jpg"


def test_cascade_delete_user_removes_artisan_and_products(db_session: Session):
    # Setup full hierarchy: User -> Artisan -> Product -> ProductImage
    user = User(name="Cascade Test User", phone="+919000000001")
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    artisan = Artisan(user_id=user.id, craft_type="Wood Carving")
    db_session.add(artisan)
    db_session.commit()
    db_session.refresh(artisan)

    product = Product(
        artisan_id=artisan.id,
        name="Carved Elephant Figurine",
        category="Sculpture",
        price=Decimal("1250.00"),
    )
    db_session.add(product)
    db_session.commit()
    db_session.refresh(product)

    image = ProductImage(
        product_id=product.id,
        original_url="https://example.com/elephant.jpg",
    )
    db_session.add(image)
    db_session.commit()
    db_session.refresh(image)

    user_id = user.id
    artisan_id = artisan.id
    product_id = product.id
    image_id = image.id

    # Delete User -> should cascade delete Artisan, Product, ProductImage
    db_session.delete(user)
    db_session.commit()

    assert db_session.get(User, user_id) is None
    assert db_session.get(Artisan, artisan_id) is None
    assert db_session.get(Product, product_id) is None
    assert db_session.get(ProductImage, image_id) is None


def test_cascade_delete_product_removes_images(db_session: Session):
    user = User(name="Artisan Two", phone="+919000000002")
    db_session.add(user)
    db_session.commit()

    artisan = Artisan(user_id=user.id, craft_type="Pottery")
    db_session.add(artisan)
    db_session.commit()

    product = Product(artisan_id=artisan.id, name="Clay Vase", category="Pottery", price=Decimal("450.00"))
    db_session.add(product)
    db_session.commit()

    image1 = ProductImage(product_id=product.id, original_url="https://example.com/vase1.jpg")
    image2 = ProductImage(product_id=product.id, original_url="https://example.com/vase2.jpg")
    db_session.add_all([image1, image2])
    db_session.commit()

    product_id = product.id
    img1_id = image1.id
    img2_id = image2.id

    db_session.delete(product)
    db_session.commit()

    assert db_session.get(Product, product_id) is None
    assert db_session.get(ProductImage, img1_id) is None
    assert db_session.get(ProductImage, img2_id) is None
    # Artisan and user still exist
    assert db_session.get(Artisan, artisan.id) is not None


def test_pydantic_schema_validation():
    valid_payload = {
        "artisan_id": 1,
        "name": "Handmade Clay Pot",
        "category": "Pottery",
        "description": "Terracotta water pot",
        "material": "Clay",
        "price": 350.00,
        "status": "draft",
    }
    product_create = ProductCreate(**valid_payload)
    assert product_create.name == "Handmade Clay Pot"
    assert product_create.price == Decimal("350.00")

    user_payload = {
        "name": "Amit Sharma",
        "phone": "+919876500000",
        "role": "artisan",
        "language": "en",
    }
    user_create = UserCreate(**user_payload)
    assert user_create.name == "Amit Sharma"
