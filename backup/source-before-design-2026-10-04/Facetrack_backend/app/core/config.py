from pydantic_settings import BaseSettings, SettingsConfigDict
 
 
class Settings(BaseSettings):
    """Reads values from .env automatically — no manual os.getenv() calls
    scattered through the codebase. Add a new field here whenever a new
    setting is needed, and it becomes available everywhere as settings.field_name.
    """
 
    database_url: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24  # 1 day
 
    model_config = SettingsConfigDict(env_file=".env")
 
 
settings = Settings()
 
