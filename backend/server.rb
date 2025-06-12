require 'json'
require 'webrick'

class ChatServer
  def initialize(port: 3000, root: File.expand_path('../frontend', __dir__))
    @messages = []
    @server = WEBrick::HTTPServer.new(
      Port: port,
      DocumentRoot: root,
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, 0)
    )
    @server.mount_proc('/messages') { |req, res| handle_messages(req, res) }
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
end

ChatServer.new.start
