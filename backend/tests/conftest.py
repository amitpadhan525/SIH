import pytest
from typing import Generator
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from backend.app.db.base import Base
from backend.app.db.session import get_db
from backend.app.main import app
from backend.app.models import User, Artisan, Product, ProductImage  # Ensure models loaded

# Use in-memory SQLite database for fast and isolated unit/integration tests
TEST_DATABASE_URL = "sqlite:///:memory:"

test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

# Enable foreign keys constraint enforcement in SQLite for accurate ON DELETE CASCADE emulation
@event.listens_for(test_engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=test_engine,
)


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """Create all tables in test database once for test session."""
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Provide a clean transactional session for each test function."""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    if transaction.is_active:
        transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    """FastAPI TestClient with get_db dependency overridden to use test session."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def sample_artisan(db_session: Session) -> Artisan:
    user = User(
        name="Sunita Devi",
        phone="+919811122233",
        role="artisan",
        language="hi",
        location="Madhubani, Bihar",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    artisan = Artisan(
        user_id=user.id,
        craft_type="Madhubani Painting",
    )
    db_session.add(artisan)
    db_session.commit()
    db_session.refresh(artisan)
    return artisan


@pytest.fixture
def second_artisan(db_session: Session) -> Artisan:
    user = User(
        name="Gopal Das",
        phone="+919844455566",
        role="artisan",
        language="hi",
        location="Khurja, UP",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    artisan = Artisan(
        user_id=user.id,
        craft_type="Ceramic Pottery",
    )
    db_session.add(artisan)
    db_session.commit()
    db_session.refresh(artisan)
    return artisan


@pytest.fixture
def auth_headers(sample_artisan: Artisan) -> dict:
    from backend.app.core.security import create_access_token
    token = create_access_token({
        "sub": str(sample_artisan.user_id),
        "role": sample_artisan.user.role,
        "name": sample_artisan.user.name,
        "phone": sample_artisan.user.phone,
        "artisan_id": sample_artisan.id,
    })
    return {"Authorization": f"Bearer {token}"}

