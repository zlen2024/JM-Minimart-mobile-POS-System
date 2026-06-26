from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for
from flask_login import current_user, login_required

from app.extensions import db
from app.models import Product, Sale, SaleItem

pos_bp = Blueprint("pos", __name__, url_prefix="/pos")

CART_SESSION_KEY = "cart"


def _get_cart():
    return session.setdefault(CART_SESSION_KEY, {})


def _cart_items():
    cart = _get_cart()
    items = []
    total_cents = 0
    for product_id_str, qty in cart.items():
        product = Product.query.get(int(product_id_str))
        if not product:
            continue
        subtotal = product.price_cents * qty
        total_cents += subtotal
        items.append({"product": product, "quantity": qty, "subtotal_cents": subtotal})
    return items, total_cents


@pos_bp.route("/")
@login_required
def terminal():
    query = request.args.get("q", "").strip()
    products_query = Product.query.filter_by(is_active=True)
    if query:
        like = f"%{query}%"
        products_query = products_query.filter(
            db.or_(Product.name.ilike(like), Product.barcode.ilike(like))
        )
    products = products_query.order_by(Product.name).all()
    cart_items, cart_total_cents = _cart_items()
    return render_template(
        "pos/terminal.html",
        products=products,
        query=query,
        cart_items=cart_items,
        cart_total_cents=cart_total_cents,
    )


@pos_bp.route("/cart/add", methods=["POST"])
@login_required
def cart_add():
    cart = _get_cart()
    product_id = request.form.get("product_id")
    barcode = request.form.get("barcode", "").strip()

    product = None
    if barcode:
        product = Product.query.filter_by(barcode=barcode, is_active=True).first()
        if not product:
            flash(f'No product found for barcode "{barcode}".', "danger")
    elif product_id:
        product = Product.query.get(int(product_id))

    if product:
        current_qty = cart.get(str(product.id), 0)
        if current_qty + 1 > product.stock_qty:
            flash(f'Only {product.stock_qty} of "{product.name}" in stock.', "warning")
        else:
            cart[str(product.id)] = current_qty + 1
            session.modified = True

    return redirect(url_for("pos.terminal", q=request.form.get("q", "")))


@pos_bp.route("/cart/update", methods=["POST"])
@login_required
def cart_update():
    cart = _get_cart()
    product_id = request.form.get("product_id")
    action = request.form.get("action")

    if product_id in cart:
        product = Product.query.get(int(product_id))
        if action == "increment" and product and cart[product_id] + 1 <= product.stock_qty:
            cart[product_id] += 1
        elif action == "decrement":
            cart[product_id] -= 1
            if cart[product_id] <= 0:
                del cart[product_id]
        elif action == "remove":
            del cart[product_id]
        session.modified = True

    return redirect(url_for("pos.terminal"))


@pos_bp.route("/cart/clear", methods=["POST"])
@login_required
def cart_clear():
    session[CART_SESSION_KEY] = {}
    return redirect(url_for("pos.terminal"))


@pos_bp.route("/checkout", methods=["POST"])
@login_required
def checkout():
    cart_items, total_cents = _cart_items()
    if not cart_items:
        flash("Cart is empty.", "warning")
        return redirect(url_for("pos.terminal"))

    for entry in cart_items:
        if entry["quantity"] > entry["product"].stock_qty:
            flash(f'Not enough stock for "{entry["product"].name}".', "danger")
            return redirect(url_for("pos.terminal"))

    payment_method = request.form.get("payment_method", "cash")
    sale = Sale(user_id=current_user.id, total_cents=total_cents, payment_method=payment_method)
    db.session.add(sale)
    db.session.flush()

    for entry in cart_items:
        product = entry["product"]
        db.session.add(
            SaleItem(
                sale_id=sale.id,
                product_id=product.id,
                product_name=product.name,
                quantity=entry["quantity"],
                unit_price_cents=product.price_cents,
                subtotal_cents=entry["subtotal_cents"],
            )
        )
        product.stock_qty -= entry["quantity"]

    db.session.commit()
    session[CART_SESSION_KEY] = {}
    flash("Sale completed.", "success")
    return redirect(url_for("pos.receipt", sale_id=sale.id))


@pos_bp.route("/receipt/<int:sale_id>")
@login_required
def receipt(sale_id):
    sale = Sale.query.get(sale_id)
    if not sale:
        abort(404)
    return render_template("pos/receipt.html", sale=sale)
