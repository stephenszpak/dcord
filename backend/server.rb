require 'json'
require 'webrick'
require 'pg'
require 'digest'

class ChatServer
  def initialize(port: 3000, root: File.expand_path('../frontend', __dir__))
    @db_params = { dbname: 'dcord' }

    PG.connect(**@db_params) do |conn|
      create_users_table(conn)
      create_chatrooms_table(conn)
      create_memberships_table(conn)
      create_messages_table(conn)
      seed_test_data(conn)
    end


    @server = WEBrick::HTTPServer.new(
      Port: port,
      DocumentRoot: root,
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, 0)
    )
    @server.mount_proc('/messages') { |req, res| handle_messages(req, res) }
    @server.mount_proc('/register') { |req, res| handle_register(req, res) }
    @server.mount_proc('/login') { |req, res| handle_login(req, res) }
    @server.mount_proc('/logout') { |req, res| handle_logout(req, res) }
    @server.mount_proc('/chatrooms') { |req, res| handle_chatrooms(req, res) }
    @server.mount_proc('/add_user') { |req, res| handle_add_user(req, res) }
    @server.mount_proc('/remove_user') { |req, res| handle_remove_user(req, res) }
    @server.mount_proc('/members') { |req, res| handle_members(req, res) }
    @server.mount_proc('/avatar') { |req, res| handle_avatar(req, res) }
  end

  def start
    trap('INT') { @server.shutdown }
    @server.start
  end

  private

  def with_conn
    conn = PG.connect(**@db_params)
    begin
      yield conn
    ensure
      conn.close
    end
  end

  def handle_messages(req, res)
    res['Content-Type'] = 'application/json'
    case req.request_method
    when 'GET'
      chatroom_id = req.query['chatroom_id']
      if chatroom_id
        with_conn do |conn|
          result = conn.exec_params(
            'SELECT users.username, content FROM messages JOIN users ON users.id=messages.user_id WHERE chatroom_id=$1 ORDER BY messages.id',
            [chatroom_id]
          )
          res.body = result.map { |r| { 'user' => r['username'], 'content' => r['content'] } }.to_json
        end
      else
        res.body = [].to_json
      end
    when 'POST'
      begin
        data = JSON.parse(req.body)
        user_id = user_id_for(data['user'])
        with_conn do |conn|
          conn.exec_params('INSERT INTO messages(chatroom_id, user_id, content) VALUES($1,$2,$3)',
                          [data['chatroom_id'], user_id, data['content']])
          result = conn.exec_params(
            'SELECT users.username, content FROM messages JOIN users ON users.id=messages.user_id WHERE chatroom_id=$1 ORDER BY messages.id',
            [data['chatroom_id']]
          )
          res.body = result.map { |r| { 'user' => r['username'], 'content' => r['content'] } }.to_json
        end
      rescue JSON::ParserError
        res.status = 400
        res.body = { error: 'invalid JSON' }.to_json
      end
    else
      res.status = 405
    end
  end

  def create_users_table(conn)
    conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_digest TEXT NOT NULL,
        online BOOLEAN DEFAULT FALSE,
        avatar TEXT
      );
    SQL
    conn.exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS online BOOLEAN DEFAULT FALSE')
    conn.exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar TEXT')
  end

  def create_chatrooms_table(conn)
    conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS chatrooms (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        admin_id INTEGER REFERENCES users(id)
      );
    SQL
  end

  def create_memberships_table(conn)
    conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS memberships (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        chatroom_id INTEGER REFERENCES chatrooms(id),
        UNIQUE (user_id, chatroom_id)
      );
    SQL
  end

  def create_messages_table(conn)
    conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        chatroom_id INTEGER REFERENCES chatrooms(id),
        user_id INTEGER REFERENCES users(id),
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    SQL
  end

  def seed_test_data(conn)
    count = conn.exec('SELECT COUNT(*) FROM users')[0]['count'].to_i

    return unless count.zero?

    digest = Digest::SHA256.hexdigest('password')
    user_ids = []
    1.upto(10) do |i|
      online = i <= 3
      result = conn.exec_params(

        'INSERT INTO users(username, password_digest, online) VALUES($1,$2,$3) RETURNING id',
        ["user#{i}", digest, online]
      )
      user_ids << result[0]['id']
    end

    chat = conn.exec_params('SELECT id FROM chatrooms WHERE name=$1', ['test'])
    if chat.ntuples.zero?
      chat_id = conn.exec_params('INSERT INTO chatrooms(name, admin_id) VALUES($1,$2) RETURNING id', ['test', user_ids.first])[0]['id']
    else
      chat_id = chat[0]['id']
    end

    user_ids.each do |uid|
      conn.exec_params('INSERT INTO memberships(user_id, chatroom_id) VALUES($1,$2) ON CONFLICT DO NOTHING', [uid, chat_id])
    end
  end

  def handle_register(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      digest = Digest::SHA256.hexdigest(data['password'].to_s)
      with_conn { |conn| conn.exec_params('INSERT INTO users(username, password_digest) VALUES($1, $2)', [data['username'], digest]) }
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
      with_conn do |conn|
        result = conn.exec_params('SELECT * FROM users WHERE username=$1 AND password_digest=$2', [data['username'], digest])
        if result.ntuples == 1
          conn.exec_params('UPDATE users SET online=true WHERE username=$1', [data['username']])
          res.body = { success: true }.to_json
        else
          res.status = 401
          res.body = { error: 'invalid credentials' }.to_json
        end
      end
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end

  def handle_logout(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      with_conn { |conn| conn.exec_params('UPDATE users SET online=false WHERE username=$1', [data['username']]) }
      res.body = { success: true }.to_json
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
        with_conn do |conn|
          result = conn.exec_params(
            'SELECT c.id, c.name, c.admin_id FROM chatrooms c JOIN memberships m ON c.id=m.chatroom_id JOIN users u ON u.id=m.user_id WHERE u.username=$1',
            [user]
          )
          res.body = result.map { |r| { id: r['id'].to_i, name: r['name'], admin_id: r['admin_id'].to_i } }.to_json
        end
      else
        res.body = [].to_json
      end
    when 'POST'
      begin
        data = JSON.parse(req.body)
        user_id = user_id_for(data['user'])
        with_conn do |conn|
          result = conn.exec_params('INSERT INTO chatrooms(name, admin_id) VALUES($1,$2) RETURNING id', [data['name'], user_id])
          chatroom_id = result[0]['id']
          conn.exec_params('INSERT INTO memberships(user_id, chatroom_id) VALUES($1,$2)', [user_id, chatroom_id])
          res.body = { id: chatroom_id.to_i, name: data['name'], admin_id: user_id }.to_json
        end
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
      with_conn do |conn|
        admin_check = conn.exec_params('SELECT admin_id FROM chatrooms WHERE id=$1', [chatroom_id])
        if admin_check.ntuples == 1 && admin_check[0]['admin_id'].to_i == admin_id
          conn.exec_params('INSERT INTO memberships(user_id, chatroom_id) VALUES($1,$2) ON CONFLICT DO NOTHING', [target_id, chatroom_id])
          res.body = { success: true }.to_json
        else
          res.status = 403
          res.body = { error: 'not admin' }.to_json
        end
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
      with_conn do |conn|
        admin_check = conn.exec_params('SELECT admin_id FROM chatrooms WHERE id=$1', [chatroom_id])
        if admin_check.ntuples == 1 && admin_check[0]['admin_id'].to_i == admin_id
          conn.exec_params('DELETE FROM memberships WHERE user_id=$1 AND chatroom_id=$2', [target_id, chatroom_id])
          res.body = { success: true }.to_json
        else
          res.status = 403
          res.body = { error: 'not admin' }.to_json
        end
      end
    rescue JSON::ParserError
      res.status = 400
      res.body = { error: 'invalid JSON' }.to_json
    end
  end

  def handle_members(req, res)
    res['Content-Type'] = 'application/json'
    return res.status = 405 unless req.request_method == 'GET'
    chatroom_id = req.query['chatroom_id']
    if chatroom_id
      with_conn do |conn|
        result = conn.exec_params(
          'SELECT u.username, u.online FROM users u JOIN memberships m ON u.id=m.user_id WHERE m.chatroom_id=$1',
          [chatroom_id]
        )
        res.body = result.map { |r| { username: r['username'], online: r['online'] == 't' } }.to_json
      end

    else
      res.body = [].to_json
    end
  end

  def handle_avatar(req, res)
    res['Content-Type'] = 'application/json'
    case req.request_method
    when 'GET'
      user = req.query['user']
      if user
        with_conn do |conn|
          result = conn.exec_params('SELECT avatar FROM users WHERE username=$1', [user])
          avatar = result.ntuples == 1 ? result[0]['avatar'] : nil
          res.body = { avatar: avatar }.to_json
        end
      else
        res.status = 400
        res.body = { error: 'user required' }.to_json
      end
    when 'POST'
      begin
        data = JSON.parse(req.body)
        with_conn do |conn|
          conn.exec_params('UPDATE users SET avatar=$1 WHERE username=$2', [data['avatar'], data['user']])
        end
        res.body = { success: true }.to_json
      rescue JSON::ParserError
        res.status = 400
        res.body = { error: 'invalid JSON' }.to_json
      end
    else
      res.status = 405
    end
  end

  def user_id_for(username)
    with_conn do |conn|
      result = conn.exec_params('SELECT id FROM users WHERE username=$1', [username])
      return result.ntuples == 1 ? result[0]['id'].to_i : nil
    end
  end
end

ChatServer.new.start
