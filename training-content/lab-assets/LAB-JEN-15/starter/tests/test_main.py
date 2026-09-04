from app.main import app

def test_health():
    with app.test_client() as c:
        assert c.get('/health').status_code == 200
