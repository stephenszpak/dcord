require 'json'
require 'webrick'
require 'pg'
require 'digest'

class ChatServer
  def initialize(port: 3000, root: File.expand_path('../frontend', __dir__))
    @conn = PG.connect(dbname: 'dcord')
    create_users_table
    create_chatrooms_table
    create_memberships_table
    create_messages_table

    @server = WEBrick::HTTPServer.new(
      Port: port,
      DocumentRoot: root,
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, 0)
    )
    @server.mount_proc('/messages') { |req, res| handle_messages(req, res) }
    @server.mount_proc('/register') { |req, res| handle_register(req, res) }
    @server.mount_proc('/login') { |req, res| handle_login(req, res) }
    @server.mount_proc('/chatrooms') { |req, res| handle_chatrooms(req, res) }
    @server.mount_proc('/add_user') { |req, res| handle_add_user(req, res) }
    @server.mount_proc('/remove_user') { |req, res| handle_remove_user(req, res) }
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
      chatroom_id = req.query['chatroom_id']
      if chatroom_id
        result = @conn.exec_params(
          'SELECT users.username, content FROM messages JOIN users ON users.id=messages.user_id WHERE chatroom_id=$1 ORDER BY messages.id',
          [chatroom_id]
        )
        res.body = result.map { |r| { 'user' => r['username'], 'content' => r['content'] } }.to_json
      else
        res.body = [].to_json
      end
    when 'POST'
      begin
        data = JSON.parse(req.body)
        user_id = user_id_for(data['user'])
        @conn.exec_params('INSERT INTO messages(chatroom_id, user_id, content) VALUES($1,$2,$3)',
                          [data['chatroom_id'], user_id, data['content']])
        result = @conn.exec_params(
          'SELECT users.username, content FROM messages JOIN users ON users.id=messages.user_id WHERE chatroom_id=$1 ORDER BY messages.id',
          [data['chatroom_id']]
        )
        res.body = result.map { |r| { 'user' => r['username'], 'content' => r['content'] } }.to_json
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

  def create_chatrooms_table
    @conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS chatrooms (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        admin_id INTEGER REFERENCES users(id)
      );
    SQL
  end

  def create_memberships_table
    @conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS memberships (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        chatroom_id INTEGER REFERENCES chatrooms(id),
        UNIQUE (user_id, chatroom_id)
      );
    SQL
  end

  def create_messages_table
    @conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        chatroom_id INTEGER REFERENCES chatrooms(id),
        user_id INTEGER REFERENCES users(id),
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
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

  def handle_chatrooms(req, res)
    res['Content-Type'] = 'application/json'
    case req.request_method
    when 'GET'
      user = req.query['user']
      if user
        result = @conn.exec_params(
          'SELECT c.id, c.name, c.admin_id FROM chatrooms c JOIN memberships m ON c.id=m.chatroom_id JOIN users u ON u.id=m.user_id WHERE u.username=$1',
          [user]
        )
        res.body = result.map { |r| { id: r['id'].to_i, name: r['name'], admin_id: r['admin_id'].to_i } }.to_json
      else
        res.body = [].to_json
      end
    when 'POST'
      begin
        data = JSON.parse(req.body)
        user_id = user_id_for(data['user'])
        result = @conn.exec_params('INSERT INTO chatrooms(name, admin_id) VALUES($1,$2) RETURNING id', [data['name'], user_id])
        chatroom_id = result[0]['id']
        @conn.exec_params('INSERT INTO memberships(user_id, chatroom_id) VALUES($1,$2)', [user_id, chatroom_id])
        res.body = { id: chatroom_id.to_i, name: data['name'], admin_id: user_id }.to_json
      rescue JSON::ParserError
        res.status = 400
        res.body = { error: 'invalid JSON' }.to_json
      end
    else
      res.status = 405
    end
  end

  def handle_add_user(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      admin_id = user_id_for(data['user'])
      target_id = user_id_for(data['username'])
      chatroom_id = data['chatroom_id']
      admin_check = @conn.exec_params('SELECT admin_id FROM chatrooms WHERE id=$1', [chatroom_id])
      if admin_check.ntuples == 1 && admin_check[0]['admin_id'].to_i == admin_id
        @conn.exec_params('INSERT INTO memberships(user_id, chatroom_id) VALUES($1,$2) ON CONFLICT DO NOTHING', [target_id, chatroom_id])
        res.body = { success: true }.to_json
      else
        res.status = 403
        res.body = { error: 'not admin' }.to_json
      end
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end

  def handle_remove_user(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      admin_id = user_id_for(data['user'])
      target_id = user_id_for(data['username'])
      chatroom_id = data['chatroom_id']
      admin_check = @conn.exec_params('SELECT admin_id FROM chatrooms WHERE id=$1', [chatroom_id])
      if admin_check.ntuples == 1 && admin_check[0]['admin_id'].to_i == admin_id
        @conn.exec_params('DELETE FROM memberships WHERE user_id=$1 AND chatroom_id=$2', [target_id, chatroom_id])
        res.body = { success: true }.to_json
      else
        res.status = 403
        res.body = { error: 'not admin' }.to_json
      end
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end

  def user_id_for(username)
    result = @conn.exec_params('SELECT id FROM users WHERE username=$1', [username])
    result.ntuples == 1 ? result[0]['id'].to_i : nil
  end
end

ChatServer.new.start
