# Week 4, Docker Compose with PostgreSQL

## What this does

Runs the incident tracker and a PostgreSQL database as a two-service Compose stack, with data persisted in a named volume.

## Requirements

- Docker Compose
- A `.env` file in `week-4/` (copy `.env.example` and fill in real values)

## Run it

```bash
docker compose up -d --build
