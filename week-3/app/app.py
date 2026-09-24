import os
from datetime import datetime, timezone

from flask import Flask, redirect, render_template, request, url_for

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev")

PORT = int(os.environ.get("PORT", 5000))

STATUSES = ["open", "in_progress", "closed"]

tickets = []
next_id = 1


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/")
def index():
    return render_template("index.html", tickets=tickets, statuses=STATUSES)


@app.route("/tickets", methods=["POST"])
def create_ticket():
    global next_id

    title = request.form.get("title", "").strip()
    description = request.form.get("description", "").strip()
    status = request.form.get("status", "open")

    if not title:
        return redirect(url_for("index"))

    tickets.insert(0, {
        "id": next_id,
        "title": title,
        "description": description,
        "status": status if status in STATUSES else "open",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    })
    next_id += 1

    return redirect(url_for("index"))


@app.route("/tickets/<int:ticket_id>/status", methods=["POST"])
def update_status(ticket_id):
    status = request.form.get("status")
    for ticket in tickets:
        if ticket["id"] == ticket_id and status in STATUSES:
            ticket["status"] = status
            break
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
