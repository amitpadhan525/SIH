import io
import os
import shutil
import tempfile
import pytest
from PIL import Image
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.config import settings
from backend.app.services.storage_service import storage_service, StorageService
from backend.app.models.user import User
from backend.app.models.artisan import Artisan
from backend.app.models.product import Product
from backend.app.models.product_image import ProductImage


def create_test_image_bytes(format_name: str = "JPEG", size: tuple = (400, 300), color: str = "red") -> bytes:
    """Helper to generate valid synthetic test image bytes in memory."""
    img = Image.new("RGB", size, color=color)
    buf = io.BytesIO()
    img.save(buf, format=format_name)
    return buf.getvalue()


@pytest.fixture(autouse=True)
def isolate_test_upload_dir(monkeypatch):
    """Isolates the storage directory to a clean temp folder for every test."""
    temp_dir = tempfile.mkdtemp()
    test_storage = StorageService(base_upload_dir=temp_dir)
    monkeypatch.setattr("backend.app.services.storage_service.storage_service", test_storage)
    monkeypatch.setattr("backend.app.api.images.storage_service", test_storage)
    monkeypatch.setattr("backend.app.config.settings.UPLOAD_DIR", temp_dir)

    yield test_storage

    shutil.rmtree(temp_dir, ignore_errors=True)


@pytest.fixture
def test_artisan_and_product(db_session):
    """Sets up a test user, artisan, and product in the test SQLite in-memory database."""
    user = User(
        id=99,
        name="Sunita Devi",
        phone="+919876543210",
        role="artisan",
        language="hi",
        location="Madhubani, Bihar",
    )
    artisan = Artisan(
        id=99,
        user_id=99,
        craft_type="Madhubani Painting",
    )
    product = Product(
        id=101,
        artisan_id=99,
        name="Handmade Silk Stole",
        category="Apparel",
        description="Authentic handwoven stole",
        material="Pure Silk",
        price=1250.00,
        status="published"
    )
    db_session.add(user)
    db_session.add(artisan)
    db_session.add(product)
    db_session.commit()
    return product


def test_upload_valid_jpeg_image(client: TestClient, test_artisan_and_product, isolate_test_upload_dir):
    img_bytes = create_test_image_bytes("JPEG", (600, 400), "blue")
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images?background_mode=white",
        files={"file": ("test_craft.jpg", img_bytes, "image/jpeg")}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["product_id"] == test_artisan_and_product.id
    assert data["original_url"].startswith("/uploads/originals/")
    assert data["processed_url"].startswith("/uploads/processed/")

    # Verify physical file existence
    orig_rel = data["original_url"].replace("/uploads/", "")
    proc_rel = data["processed_url"].replace("/uploads/", "")
    orig_path = isolate_test_upload_dir.base_dir / orig_rel
    proc_path = isolate_test_upload_dir.base_dir / proc_rel
    assert orig_path.exists()
    assert proc_path.exists()

    # Verify processed image dimensions (strictly 1024x1024)
    with Image.open(proc_path) as proc_img:
        assert proc_img.size == (1024, 1024)
        assert proc_img.format == "JPEG"


def test_upload_valid_png_image(client: TestClient, test_artisan_and_product):
    img_bytes = create_test_image_bytes("PNG", (500, 500), "green")
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images?background_mode=grey",
        files={"file": ("test_craft.png", img_bytes, "image/png")}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["original_url"].endswith(".png")


def test_upload_valid_webp_image(client: TestClient, test_artisan_and_product):
    img_bytes = create_test_image_bytes("WEBP", (400, 400), "purple")
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images?background_mode=warm",
        files={"file": ("test_craft.webp", img_bytes, "image/webp")}
    )
    assert response.status_code == 201


def test_reject_invalid_mime_and_text_file(client: TestClient, test_artisan_and_product):
    fake_bytes = b"Hello, this is not an image."
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("fake.jpg", fake_bytes, "image/jpeg")}
    )
    assert response.status_code == 400
    assert "Corrupted or invalid image" in response.json()["detail"]


def test_reject_svg_and_script_payloads(client: TestClient, test_artisan_and_product):
    svg_payload = b"<svg><script>alert('xss')</script></svg>"
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("vector.svg", svg_payload, "image/svg+xml")}
    )
    assert response.status_code == 400
    assert "disallowed" in response.json()["detail"].lower()


def test_reject_corrupted_image_bytes(client: TestClient, test_artisan_and_product):
    # Truncated JPEG header
    corrupt_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01"
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("broken.jpg", corrupt_bytes, "image/jpeg")}
    )
    assert response.status_code == 400


def test_reject_oversized_upload(client: TestClient, test_artisan_and_product, monkeypatch):
    monkeypatch.setattr("backend.app.config.settings.MAX_UPLOAD_SIZE_BYTES", 500)  # 500 bytes limit
    img_bytes = create_test_image_bytes("JPEG", (300, 300))
    assert len(img_bytes) > 500

    response = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("large.jpg", img_bytes, "image/jpeg")}
    )
    assert response.status_code == 400
    assert "exceeds maximum allowed limit" in response.json()["detail"].lower()


def test_path_traversal_filename_sanitization(client: TestClient, test_artisan_and_product, isolate_test_upload_dir):
    img_bytes = create_test_image_bytes("JPEG", (200, 200))
    # Malicious filename attempting to escape
    response = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("../../../../etc/passwd.jpg", img_bytes, "image/jpeg")}
    )
    assert response.status_code == 201
    data = response.json()
    # Ensure UUID naming was enforced and original file is stored strictly in originals dir
    assert ".." not in data["original_url"]
    orig_path = isolate_test_upload_dir.base_dir / data["original_url"].replace("/uploads/", "")
    assert str(orig_path).startswith(str(isolate_test_upload_dir.base_dir))


def test_upload_to_nonexistent_product_returns_404(client: TestClient):
    img_bytes = create_test_image_bytes("JPEG", (200, 200))
    response = client.post(
        "/products/99999/images",
        files={"file": ("craft.jpg", img_bytes, "image/jpeg")}
    )
    assert response.status_code == 404
    assert "Product with id 99999 not found" in response.json()["detail"]


def test_list_product_images(client: TestClient, test_artisan_and_product):
    # Upload two images
    img1 = create_test_image_bytes("JPEG", (200, 200), "red")
    img2 = create_test_image_bytes("PNG", (200, 200), "yellow")

    client.post(f"/products/{test_artisan_and_product.id}/images", files={"file": ("1.jpg", img1, "image/jpeg")})
    client.post(f"/products/{test_artisan_and_product.id}/images", files={"file": ("2.png", img2, "image/png")})

    response = client.get(f"/products/{test_artisan_and_product.id}/images")
    assert response.status_code == 200
    images = response.json()
    assert len(images) == 2
    assert images[0]["original_url"].startswith("/uploads/originals/")
    assert images[1]["original_url"].startswith("/uploads/originals/")


def test_delete_product_image_cleans_up_files_and_db(client: TestClient, test_artisan_and_product, isolate_test_upload_dir):
    img_bytes = create_test_image_bytes("JPEG", (300, 300))
    upload_res = client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("todelete.jpg", img_bytes, "image/jpeg")}
    )
    assert upload_res.status_code == 201
    image_id = upload_res.json()["id"]
    orig_rel = upload_res.json()["original_url"].replace("/uploads/", "")
    proc_rel = upload_res.json()["processed_url"].replace("/uploads/", "")

    orig_path = isolate_test_upload_dir.base_dir / orig_rel
    proc_path = isolate_test_upload_dir.base_dir / proc_rel
    assert orig_path.exists()
    assert proc_path.exists()

    # Delete image
    del_res = client.delete(f"/products/{test_artisan_and_product.id}/images/{image_id}")
    assert del_res.status_code == 204

    # Verify DB record is gone
    get_res = client.get(f"/products/{test_artisan_and_product.id}/images")
    assert len(get_res.json()) == 0

    # Verify files on disk were cleaned up
    assert not orig_path.exists()
    assert not proc_path.exists()


def test_delete_nonexistent_image_returns_404(client: TestClient, test_artisan_and_product):
    response = client.delete(f"/products/{test_artisan_and_product.id}/images/8888")
    assert response.status_code == 404


def test_product_deletion_cascades_product_images(client: TestClient, test_artisan_and_product, db_session):
    img_bytes = create_test_image_bytes("JPEG", (200, 200))
    client.post(
        f"/products/{test_artisan_and_product.id}/images",
        files={"file": ("cascade.jpg", img_bytes, "image/jpeg")}
    )

    # Confirm image in DB
    images_before = db_session.query(ProductImage).filter_by(product_id=test_artisan_and_product.id).all()
    assert len(images_before) == 1

    # Delete parent product
    del_res = client.delete(f"/products/{test_artisan_and_product.id}")
    assert del_res.status_code == 204

    # Verify ProductImage record was automatically cascaded
    images_after = db_session.query(ProductImage).filter_by(product_id=test_artisan_and_product.id).all()
    assert len(images_after) == 0


def test_ai_enhance_standalone_preview_does_not_create_db_record(client: TestClient, db_session):
    img_bytes = create_test_image_bytes("JPEG", (400, 400), "orange")
    res = client.post(
        "/ai/images/enhance?background_mode=warm",
        files={"file": ("preview_craft.jpg", img_bytes, "image/jpeg")}
    )
    assert res.status_code == 200
    data = res.json()
    assert data["width"] == 1024
    assert data["height"] == 1024
    assert data["background_mode"] == "warm"
    assert data["processed_url"].startswith("/uploads/previews/")

    # Ensure NO ProductImage records were created in the database for preview
    assert db_session.query(ProductImage).count() == 0


def test_ai_enhance_transparent_background_removal(client: TestClient, isolate_test_upload_dir):
    img_bytes = create_test_image_bytes("JPEG", (400, 400), "orange")
    res = client.post(
        "/ai/images/enhance?background_mode=transparent",
        files={"file": ("preview_transparent.jpg", img_bytes, "image/jpeg")}
    )
    assert res.status_code == 200
    data = res.json()
    assert data["background_mode"] == "transparent"
    assert data["processed_url"].endswith(".png")

    proc_rel = data["processed_url"].replace("/uploads/", "")
    proc_path = isolate_test_upload_dir.base_dir / proc_rel
    assert proc_path.exists()

    with Image.open(proc_path) as proc_img:
        assert proc_img.format == "PNG"
        assert proc_img.mode == "RGBA"
        assert proc_img.size == (1024, 1024)
        # Check alpha channel exists
        assert "A" in proc_img.getbands()


def test_upload_transparent_product_image(client: TestClient, test_artisan_and_product, isolate_test_upload_dir):
    img_bytes = create_test_image_bytes("JPEG", (500, 500), "purple")
    res = client.post(
        f"/products/{test_artisan_and_product.id}/images?background_mode=transparent",
        files={"file": ("transparent_craft.jpg", img_bytes, "image/jpeg")}
    )
    assert res.status_code == 201
    data = res.json()
    assert data["processed_url"].endswith(".png")

    proc_rel = data["processed_url"].replace("/uploads/", "")
    proc_path = isolate_test_upload_dir.base_dir / proc_rel
    assert proc_path.exists()

    with Image.open(proc_path) as proc_img:
        assert proc_img.format == "PNG"
        assert proc_img.mode == "RGBA"

