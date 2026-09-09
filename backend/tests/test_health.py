from fastapi.testclient import TestClient

def test_root_endpoint(client: TestClient):
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "service" in data

def test_general_health_endpoint(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_database_health_endpoint(client: TestClient):
    response = client.get("/health/db")
    assert response.status_code == 200
    data = response.json()
    assert data["database"] == "connected"
