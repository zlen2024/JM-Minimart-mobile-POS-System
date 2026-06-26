# JM Mini Mart ProPOS

A mobile-first Point of Sale (POS) and Inventory Management web app for JM Mini Mart, built as an installable **Progressive Web App (PWA)**. Same functionality as the original plan, now running in the browser with a Flask backend and SQLite database — no app store, no native build, just open it on a phone and "Add to Home Screen".

## Tech Stack

- **Backend:** Flask (Python), kept intentionally small and dependency-light
- **Database:** SQLite via SQLAlchemy ORM
- **Auth:** Flask-Login session auth with hashed passwords (username + password)
- **Frontend:** Server-rendered Jinja2 templates + plain CSS/JS (no SPA framework) — mobile-first, with a desktop layout that kicks in above 720px
- **Camera / Barcode scanning:** [html5-qrcode](https://github.com/mebjas/html5-qrcode) (loaded via CDN), uses the browser's `getUserMedia` camera API — **requires HTTPS** (or `localhost`) to work
- **Charts:** Chart.js (CDN) for the sales dashboard
- **PWA:** `manifest.json` + a service worker that caches the app shell (CSS/icons) so the app is installable; live data always comes from the server

## Money handling

Prices are stored as **integers in cents** (`price_cents`) everywhere in the database — never as floats — to avoid floating-point rounding bugs in totals. They're only converted to a decimal dollar amount at the display layer (a `currency` Jinja filter) and when the user types a price into a form, which is then parsed back into cents before saving.

## Database schema (basic POS ERD)

- **users** — id, username, password_hash, role, created_at
- **categories** — id, name
- **products** — id, name, barcode, category_id → categories, price_cents, stock_qty, low_stock_threshold, is_active
- **sales** — id, user_id → users, total_cents, payment_method, created_at
- **sale_items** — id, sale_id → sales, product_id → products, product_name (snapshot), quantity, unit_price_cents, subtotal_cents

## Setup & Run

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export FLASK_APP=run.py
flask seed-db        # creates the SQLite DB + a default admin user + sample products

python run.py         # runs on http://0.0.0.0:5000
```

Default login after seeding: **admin / admin123** — change this password in production (a real "change password" page isn't included; update it by re-hashing via the Flask shell, or extend the auth blueprint).

### Camera access in production

Browsers only grant camera access (`getUserMedia`) on secure origins. When you deploy this for real use, serve it over **HTTPS** (e.g. behind Caddy/Nginx with a TLS cert, or a platform that provides one automatically) — otherwise the barcode scanner button will fail with a permission error.

## Project layout

```
app/
  __init__.py          # app factory, blueprint registration, login gate
  config.py            # SQLite URI, secret key
  extensions.py        # db, login_manager
  models.py            # User, Category, Product, Sale, SaleItem
  cli.py               # `flask seed-db` command
  blueprints/
    auth/              # login / logout
    pos/               # cart (session-based), checkout, receipt
    inventory/         # product & category CRUD
    reporting/         # sales dashboard
  templates/           # Jinja2 templates, mobile-first CSS classes
  static/
    css/app.css
    js/, icons/
    manifest.json
    service-worker.js
run.py                  # entrypoint
requirements.txt
instance/pos.db          # SQLite file (created on first run, gitignored)
```

## Testing

No automated test suite yet. Manually verified flow: login → browse/search products → add to cart → scan barcode → checkout → printable receipt → stock decrements → sales show up on the reports dashboard.
