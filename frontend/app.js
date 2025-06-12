const { useState, useEffect } = React;

function MessageList({ messages }) {
  return (
    <div className="messages">
      {messages.map((m, idx) => (
        <div key={idx} className="message">
          <strong>{m.user}</strong>: {m.content}
        </div>
      ))}
    </div>
  );
}

function MessageInput({ onSend }) {
  const [user, setUser] = useState('');
  const [content, setContent] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSend({ user, content });
    setContent('');
  };

  return (
    <form onSubmit={handleSubmit} className="message-input">
      <input
        name="user"
        placeholder="User"
        value={user}
        onChange={(e) => setUser(e.target.value)}
      />
      <input
        name="content"
        placeholder="Message"
        value={content}
        onChange={(e) => setContent(e.target.value)}
      />
      <button type="submit">Send</button>
    </form>
  );
}

function ChatApp() {
  const [messages, setMessages] = useState([]);

  const loadMessages = () => {
    fetch('/messages')
      .then((r) => r.json())
      .then((data) => setMessages(data));
  };

  useEffect(loadMessages, []);

  const sendMessage = (msg) => {
    fetch('/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(msg),
    }).then(loadMessages);
  };

  return (
    <div className="chat-app">
      <h1>Dcord</h1>
      <MessageList messages={messages} />
      <MessageInput onSend={sendMessage} />
    </div>
  );
}

ReactDOM.render(<ChatApp />, document.getElementById('root'));
