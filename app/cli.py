import click

from app.extensions import db
from app.models import Category, Product, User


def register_cli(app):
    @app.cli.command("seed-db")
    def seed_db():
        """Seed the database with a default admin user and starter catalog."""
        if User.query.filter_by(username="admin").first() is None:
            admin = User(username="admin", role="admin")
            admin.set_password("admin123")
            db.session.add(admin)
            click.echo("Created default admin user (username: admin, password: admin123).")
            click.echo("IMPORTANT: change this password after first login.")

        if Category.query.count() == 0:
            beverages = Category(name="Beverages")
            snacks = Category(name="Snacks")
            household = Category(name="Household")
            db.session.add_all([beverages, snacks, household])
            db.session.flush()

            db.session.add_all(
                [
                    Product(
                        name="Bottled Water 500ml",
                        barcode="4800000000017",
                        category_id=beverages.id,
                        price_cents=2500,
                        stock_qty=50,
                        low_stock_threshold=10,
                    ),
                    Product(
                        name="Instant Noodles",
                        barcode="4800000000024",
                        category_id=snacks.id,
                        price_cents=1500,
                        stock_qty=40,
                        low_stock_threshold=10,
                    ),
                    Product(
                        name="Dish Soap 250ml",
                        barcode="4800000000031",
                        category_id=household.id,
                        price_cents=6500,
                        stock_qty=20,
                        low_stock_threshold=5,
                    ),
                ]
            )
            click.echo("Seeded starter categories and products.")

        db.session.commit()
        click.echo("Done.")
