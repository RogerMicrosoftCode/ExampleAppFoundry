"""
Tests básicos para el módulo app
"""
import pytest


def test_import_modules():
    """Test que todos los módulos se importen correctamente"""
    from app import config
    from app import foundry_client
    from app import chat_engine
    from app import utils
    
    assert config is not None
    assert foundry_client is not None
    assert chat_engine is not None
    assert utils is not None
