from app.calculator import Calculator

def test_add():
    assert Calculator().add(2, 3) == 5
