require 'json'
require 'webrick'
require 'pg'
require 'digest'

class ChatServer
  def initialize(port: 3000, root: File.expand_path('../frontend', __dir__))
    @messages = []
    @conn = PG.connect(dbname: 'dcord')
    create_users_table

    @server = WEBrick::HTTPServer.new(
      Port: port,
      DocumentRoot: root,
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, 0)
    )
    @server.mount_proc('/messages') { |req, res| handle_messages(req, res) }
    @server.mount_proc('/register') { |req, res| handle_register(req, res) }
    @server.mount_proc('/login') { |req, res| handle_login(req, res) }
  end

  def start
    trap('INT') { @server.shutdown }
    @server.start
  end

  private

  def handle_messages(req, res)
    res['Content-Type'] = 'application/json'
    case req.request_method
    when 'GET'
      res.body = @messages.to_json
    when 'POST'
      begin
        data = JSON.parse(req.body)
        @messages << { 'user' => data['user'], 'content' => data['content'] }
        res.body = @messages.to_json
      rescue JSON::ParserError
        res.status = 400
        res.body = { error: 'invalid JSON' }.to_json
      end
    else
      res.status = 405
    end
  end

  def create_users_table
    @conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_digest TEXT NOT NULL
      );
    SQL
  end

  def handle_register(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      digest = Digest::SHA256.hexdigest(data['password'].to_s)
      @conn.exec_params('INSERT INTO users(username, password_digest) VALUES($1, $2)', [data['username'], digest])
      res.body = { success: true }.to_json
    rescue PG::Error
      res.status = 400
      res.body = { error: 'username taken' }.to_json
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end

  def handle_login(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      digest = Digest::SHA256.hexdigest(data['password'].to_s)
      result = @conn.exec_params('SELECT * FROM users WHERE username=$1 AND password_digest=$2', [data['username'], digest])
      if result.ntuples == 1
        res.body = { success: true }.to_json
      else
        res.status = 401
        res.body = { error: 'invalid credentials' }.to_json
      end
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end
end

ChatServer.new.start
