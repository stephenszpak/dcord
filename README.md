# Dcord - Mock Discord

This project is a very small mock chat application inspired by Discord. It uses a React front end and a lightweight Ruby server based on `WEBrick`.

## Setup

Install Ruby and Node dependencies (optional, required only if you want to use Bundler and npm):

```bash
bundle install
npm install --prefix frontend
```

## Running the server

```bash
ruby backend/server.rb
```

The server runs on [http://localhost:3000](http://localhost:3000) and serves the React app from the `frontend` directory. Messages are stored only in memory and will reset whenever the server restarts.

## Features

* View and send messages
* Minimal setup without Rails

This is a simplified demonstration. A real project would use frameworks like Rails and a persistent database.
