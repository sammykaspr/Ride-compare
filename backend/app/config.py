from functools import lru_cache
from pathlib import Path

import yaml
from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/ridecompare"
    google_maps_api_key: str = ""
    pricing_config_path: str = str(ROOT / "config" / "pricing.yaml")
    surge_model_path: str = str(ROOT / "scripts" / "surge_model.pkl")
    use_mock_distance: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()


@lru_cache
def get_pricing_config() -> dict:
    with open(get_settings().pricing_config_path) as f:
        return yaml.safe_load(f)
