from datetime import datetime, timedelta

from flask import Blueprint, render_template, request
from flask_login import login_required
from sqlalchemy import func

from app.extensions import db
from app.models import Sale

reporting_bp = Blueprint("reporting", __name__, url_prefix="/reports")


@reporting_bp.route("/")
@login_required
def dashboard():
    today = datetime.utcnow().date()
    today_start = datetime(today.year, today.month, today.day)
    week_start = today_start - timedelta(days=6)

    today_total = (
        db.session.query(func.coalesce(func.sum(Sale.total_cents), 0))
        .filter(Sale.created_at >= today_start)
        .scalar()
    )
    week_total = (
        db.session.query(func.coalesce(func.sum(Sale.total_cents), 0))
        .filter(Sale.created_at >= week_start)
        .scalar()
    )
    today_count = Sale.query.filter(Sale.created_at >= today_start).count()

    daily_totals = []
    for i in range(6, -1, -1):
        day = today_start - timedelta(days=i)
        next_day = day + timedelta(days=1)
        total = (
            db.session.query(func.coalesce(func.sum(Sale.total_cents), 0))
            .filter(Sale.created_at >= day, Sale.created_at < next_day)
            .scalar()
        )
        daily_totals.append({"label": day.strftime("%a"), "total_cents": total})

    recent_sales = Sale.query.order_by(Sale.created_at.desc()).limit(20).all()

    return render_template(
        "reporting/dashboard.html",
        today_total_cents=today_total,
        week_total_cents=week_total,
        today_count=today_count,
        daily_totals=daily_totals,
        recent_sales=recent_sales,
    )
