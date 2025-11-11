"""
Tests para el módulo de configuración
"""
import pytest
import os
from unittest.mock import patch
from app.config import AzureAIFoundryConfig, BotConfig, AppConfig


class TestAzureAIFoundryConfig:
    """Tests para AzureAIFoundryConfig"""
    
    @patch.dict(os.environ, {
        "AZURE_SUBSCRIPTION_ID": "test-sub-id",
        "AZURE_RESOURCE_GROUP": "test-rg",
        "AZURE_AI_PROJECT_NAME": "test-project",
        "AZURE_OPENAI_ENDPOINT": "https://test.openai.azure.com/",
        "AZURE_OPENAI_API_KEY": "test-key",
        "AZURE_OPENAI_DEPLOYMENT_NAME": "gpt-4",
    })
    def test_validate_success(self):
        """Test validación exitosa"""
        assert AzureAIFoundryConfig.validate() is True
    
    @patch.dict(os.environ, {}, clear=True)
    def test_validate_missing_fields(self):
        """Test validación con campos faltantes"""
        with pytest.raises(ValueError):
            AzureAIFoundryConfig.validate()
    
    def test_get_info(self):
        """Test obtener información de configuración"""
        info = AzureAIFoundryConfig.get_info()
        assert isinstance(info, dict)
        assert "project" in info
        assert "deployment" in info


class TestBotConfig:
    """Tests para BotConfig"""
    
    @patch.dict(os.environ, {
        "MICROSOFT_APP_ID": "test-app-id",
        "MICROSOFT_APP_PASSWORD": "test-password",
    })
    def test_validate_success(self):
        """Test validación exitosa"""
        assert BotConfig.validate() is True
    
    @patch.dict(os.environ, {}, clear=True)
    def test_validate_missing_fields(self):
        """Test validación con campos faltantes"""
        with pytest.raises(ValueError):
            BotConfig.validate()
