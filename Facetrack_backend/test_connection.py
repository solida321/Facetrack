from sqlalchemy import text
from app.core.database import engine

with engine.connect() as connection:
    result = connection.execute(text("SELECT version();"))
    print("Connected successfully. Postgres version:")
    print(result.fetchone()[0])