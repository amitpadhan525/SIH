from alembic.config import Config
from alembic import command
from pathlib import Path

def test_alembic_upgrade_and_downgrade(tmp_path: Path):
    """Test that Alembic can run migration upgrade and downgrade successfully."""
    db_file = tmp_path / "test_migration.db"
    db_url = f"sqlite:///{db_file}"

    backend_dir = Path(__file__).resolve().parent.parent
    alembic_ini_path = backend_dir / "alembic.ini"

    alembic_cfg = Config(str(alembic_ini_path))
    alembic_cfg.set_main_option("script_location", str(backend_dir / "alembic"))
    alembic_cfg.set_main_option("sqlalchemy.url", db_url)

    # 1. Run upgrade to head
    command.upgrade(alembic_cfg, "head")

    # 2. Run downgrade back to base
    command.downgrade(alembic_cfg, "base")

    # 3. Upgrade back to head
    command.upgrade(alembic_cfg, "head")
