from flask import Flask, redirect, request, url_for
from flask_login import current_user

from app.config import Config
from app.extensions import db, login_manager


def create_app(config_class=Config):
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object(config_class)

    db.init_app(app)
    login_manager.init_app(app)

    from app.blueprints.auth import auth_bp
    from app.blueprints.pos import pos_bp
    from app.blueprints.inventory import inventory_bp
    from app.blueprints.reporting import reporting_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(pos_bp)
    app.register_blueprint(inventory_bp)
    app.register_blueprint(reporting_bp)

    from app import models  # noqa: F401

    @app.template_filter("currency")
    def currency_filter(cents):
        return "{:,.2f}".format((cents or 0) / 100)

    from app.cli import register_cli

    register_cli(app)

    with app.app_context():
        db.create_all()

    @app.before_request
    def require_login():
        public_endpoints = {"auth.login", "manifest", "service_worker", "static"}
        if request.endpoint in public_endpoints or request.endpoint is None:
            return None
        if not current_user.is_authenticated:
            return redirect(url_for("auth.login", next=request.path))

    @app.route("/manifest.json")
    def manifest():
        from flask import send_from_directory

        return send_from_directory(app.static_folder, "manifest.json")

    @app.route("/service-worker.js")
    def service_worker():
        from flask import send_from_directory

        return send_from_directory(app.static_folder, "service-worker.js")

    return app
