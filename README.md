# Dcord - Mock Discord

This project is a very small mock chat application inspired by Discord. It uses a React front end and a lightweight Ruby server based on `WEBrick`.

## Setup

Install Ruby and Node dependencies (optional, required only if you want to use Bundler and npm). You will also need a local PostgreSQL server:

```bash
bundle install
npm install --prefix frontend
```

### Database setup

1. Ensure PostgreSQL is installed and running locally.
2. Create a database named `dcord` (the server creates tables on startup):
   ```bash
   createdb dcord
   ```
3. If your Postgres instance requires a specific user or password, set the
   `PGUSER` and `PGPASSWORD` environment variables before starting the server.

## Running the server

```bash
ruby backend/server.rb
```

The server runs on [http://localhost:3000](http://localhost:3000) and serves the React app from the `frontend` directory. Messages are stored only in memory and will reset whenever the server restarts.

## Features

* Create an account and login
* View and send messages once authenticated
* Minimal setup without Rails

This is a simplified demonstration. A real project would use frameworks like Rails and a persistent database.
