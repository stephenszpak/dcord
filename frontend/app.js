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

function MessageInput({ onSend, user }) {
  const [content, setContent] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSend({ user, content });
    setContent('');
  };

  return (
    <form onSubmit={handleSubmit} className="message-input">
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

function ChatApp({ user }) {
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
      <MessageInput onSend={sendMessage} user={user} />
    </div>
  );
}

function LoginForm({ onLogin, onShowRegister }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    fetch('/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    }).then((r) => {
      if (r.ok) {
        onLogin(username);
      } else {
        alert('Invalid credentials');
      }
    });
  };

  return (
    <form onSubmit={handleSubmit} className="login-form">
      <h1>Login</h1>
      <input
        name="username"
        placeholder="Username"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
      />
      <input
        type="password"
        name="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <button type="submit">Login</button>
      <div>
        <a href="#" onClick={onShowRegister}>Create Account</a>
      </div>
    </form>
  );
}

function RegisterForm({ onRegister, onShowLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [verify, setVerify] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (password !== verify) {
      alert('Passwords do not match');
      return;
    }
    fetch('/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    }).then((r) => {
      if (r.ok) {
        onRegister(username);
      } else {
        alert('Error creating account');
      }
    });
  };

  return (
    <form onSubmit={handleSubmit} className="register-form">
      <h1>Create Account</h1>
      <input
        name="username"
        placeholder="Username"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
      />
      <input
        type="password"
        name="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <input
        type="password"
        name="verify"
        placeholder="Verify Password"
        value={verify}
        onChange={(e) => setVerify(e.target.value)}
      />
      <button type="submit">Create Account</button>
      <div>
        <a href="#" onClick={onShowLogin}>Back to Login</a>
      </div>
    </form>
  );
}

function App() {
  const [user, setUser] = useState(null);
  const [showRegister, setShowRegister] = useState(false);

  if (!user) {
    return showRegister ? (
      <RegisterForm
        onRegister={setUser}
        onShowLogin={() => setShowRegister(false)}
      />
    ) : (
      <LoginForm
        onLogin={setUser}
        onShowRegister={() => setShowRegister(true)}
      />
    );
  }

  return <ChatApp user={user} />;
}

ReactDOM.render(<App />, document.getElementById('root'));
