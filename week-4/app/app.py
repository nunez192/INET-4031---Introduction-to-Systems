import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
from flask import Flask, redirect, render_template, request, url_for

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev")

PORT = int(os.environ.get("PORT", 5000))

STATUSES = ["open", "in_progress", "closed"]

DATABASE_URL = os.environ.get("DATABASE_URL") or (
    f"postgresql://{os.environ.get('POSTGRES_USER')}:"
    f"{os.environ.get('POSTGRES_PASSWORD')}@db:5432/"
    f"{os.environ.get('POSTGRES_DB')}"
)


@contextmanager
def get_conn():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS tickets (
                    id SERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    status TEXT NOT NULL DEFAULT 'open',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
            """)


init_db()


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/")
def index():
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM tickets ORDER BY id DESC")
            tickets = cur.fetchall()
    return render_template("index.html", tickets=tickets, statuses=STATUSES)


@app.route("/tickets", methods=["POST"])
def create_ticket():
    title = request.form.get("title", "").strip()
    description = request.form.get("description", "").strip()
    status = request.form.get("status", "open")
    status = status if status in STATUSES else "open"

    if not title:
        return redirect(url_for("index"))

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tickets (title, description, status) VALUES (%s, %s, %s)",
                (title, description, status),
            )

    return redirect(url_for("index"))


@app.route("/tickets/<int:ticket_id>/status", methods=["POST"])
def update_status(ticket_id):
    status = request.form.get("status")
    if status in STATUSES:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE tickets SET status = %s WHERE id = %s",
                    (status, ticket_id),
                )
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
