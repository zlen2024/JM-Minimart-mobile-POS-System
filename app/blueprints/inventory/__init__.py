from flask import Blueprint, flash, redirect, render_template, request, url_for
from flask_login import login_required

from app.extensions import db
from app.models import Category, Product

inventory_bp = Blueprint("inventory", __name__, url_prefix="/inventory")


def _price_to_cents(raw_price):
    raw_price = (raw_price or "0").strip()
    try:
        return int(round(float(raw_price) * 100))
    except ValueError:
        return 0


@inventory_bp.route("/products")
@login_required
def products():
    query = request.args.get("q", "").strip()
    products_query = Product.query
    if query:
        like = f"%{query}%"
        products_query = products_query.filter(
            db.or_(Product.name.ilike(like), Product.barcode.ilike(like))
        )
    items = products_query.order_by(Product.name).all()
    return render_template("inventory/products.html", products=items, query=query)


@inventory_bp.route("/products/new", methods=["GET", "POST"])
@login_required
def new_product():
    categories = Category.query.order_by(Category.name).all()

    if request.method == "POST":
        name = request.form.get("name", "").strip()
        barcode = request.form.get("barcode", "").strip() or None
        category_id = request.form.get("category_id") or None
        price_cents = _price_to_cents(request.form.get("price"))
        stock_qty = int(request.form.get("stock_qty") or 0)
        low_stock_threshold = int(request.form.get("low_stock_threshold") or 5)

        if not name:
            flash("Product name is required.", "danger")
        elif barcode and Product.query.filter_by(barcode=barcode).first():
            flash("A product with that barcode already exists.", "danger")
        else:
            product = Product(
                name=name,
                barcode=barcode,
                category_id=category_id,
                price_cents=price_cents,
                stock_qty=stock_qty,
                low_stock_threshold=low_stock_threshold,
            )
            db.session.add(product)
            db.session.commit()
            flash(f'Added "{name}" to inventory.', "success")
            return redirect(url_for("inventory.products"))

    return render_template("inventory/product_form.html", categories=categories, product=None)


@inventory_bp.route("/products/<int:product_id>/edit", methods=["GET", "POST"])
@login_required
def edit_product(product_id):
    product = Product.query.get_or_404(product_id)
    categories = Category.query.order_by(Category.name).all()

    if request.method == "POST":
        name = request.form.get("name", "").strip()
        barcode = request.form.get("barcode", "").strip() or None
        existing = Product.query.filter(Product.barcode == barcode, Product.id != product.id).first()

        if not name:
            flash("Product name is required.", "danger")
        elif barcode and existing:
            flash("A product with that barcode already exists.", "danger")
        else:
            product.name = name
            product.barcode = barcode
            product.category_id = request.form.get("category_id") or None
            product.price_cents = _price_to_cents(request.form.get("price"))
            product.stock_qty = int(request.form.get("stock_qty") or 0)
            product.low_stock_threshold = int(request.form.get("low_stock_threshold") or 5)
            product.is_active = bool(request.form.get("is_active"))
            db.session.commit()
            flash(f'Updated "{name}".', "success")
            return redirect(url_for("inventory.products"))

    return render_template("inventory/product_form.html", categories=categories, product=product)


@inventory_bp.route("/products/<int:product_id>/delete", methods=["POST"])
@login_required
def delete_product(product_id):
    product = Product.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    flash(f'Deleted "{product.name}".', "info")
    return redirect(url_for("inventory.products"))


@inventory_bp.route("/categories", methods=["GET", "POST"])
@login_required
def categories():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        if not name:
            flash("Category name is required.", "danger")
        elif Category.query.filter_by(name=name).first():
            flash("That category already exists.", "danger")
        else:
            db.session.add(Category(name=name))
            db.session.commit()
            flash(f'Added category "{name}".', "success")
        return redirect(url_for("inventory.categories"))

    items = Category.query.order_by(Category.name).all()
    return render_template("inventory/categories.html", categories=items)


@inventory_bp.route("/categories/<int:category_id>/delete", methods=["POST"])
@login_required
def delete_category(category_id):
    category = Category.query.get_or_404(category_id)
    db.session.delete(category)
    db.session.commit()
    flash(f'Deleted category "{category.name}".', "info")
    return redirect(url_for("inventory.categories"))
