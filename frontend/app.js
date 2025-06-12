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

function ChatroomList({ rooms, selectedId, onSelect, onCreate }) {
  return (
    <div className="chatrooms">
      <div className="chatrooms-header">Chatrooms</div>
      <button className="create-chatroom-btn" onClick={onCreate}>
        Create Chatroom
      </button>
      {rooms.map((r) => (
        <div
          key={r.id}
          className={r.id === selectedId ? 'chatroom selected' : 'chatroom'}
          onClick={() => onSelect(r)}
        >
          {r.name}
        </div>
      ))}
    </div>
  );
}

function MemberList({ members }) {
  return (
    <div className="members">
      <div className="chatrooms-header">Members</div>
      {members.map((m) => (
        <div key={m.username} className="member" style={{ opacity: m.online ? 1 : 0.5 }}>
          {m.username}
        </div>
      ))}
    </div>
  );
}

function ChatApp({ user }) {
  const [rooms, setRooms] = useState([]);
  const [current, setCurrent] = useState(null);
  const [messages, setMessages] = useState([]);
  const [members, setMembers] = useState([]);
  const [showCreate, setShowCreate] = useState(false);
  const [newRoomName, setNewRoomName] = useState('');

  const loadRooms = () => {
    fetch('/chatrooms?user=' + encodeURIComponent(user))
      .then((r) => r.json())
      .then((data) => {
        setRooms(data);
        if (!current && data.length > 0) setCurrent(data[0]);
      });
  };

  useEffect(loadRooms, []);

  const loadMessages = () => {
    if (!current) return;
    fetch('/messages?chatroom_id=' + current.id)
      .then((r) => r.json())
      .then((data) => setMessages(data));
    fetch('/members?chatroom_id=' + current.id)
      .then((r) => r.json())
      .then((data) => setMembers(data));
  };

  useEffect(loadMessages, [current]);

  const sendMessage = (msg) => {
    if (!current) return;
    fetch('/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ...msg, chatroom_id: current.id }),
    }).then(loadMessages);
  };

  const createRoom = () => {
    setShowCreate(true);
  };

  const submitCreateRoom = () => {
    if (!newRoomName) return;
    fetch('/chatrooms', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newRoomName, user }),
    })
      .then((r) => r.json())
      .then(() => {
        setShowCreate(false);
        setNewRoomName('');
        loadRooms();
      });
  };

  return (
    <div className="chat-app">
      {showCreate && (
        <div className="dialog-backdrop">
          <div className="dialog">
            <h2>Create Chatroom</h2>
            <input
              placeholder="Chatroom Name"
              value={newRoomName}
              onChange={(e) => setNewRoomName(e.target.value)}
            />
            <div>
              <button onClick={submitCreateRoom}>Create</button>
              <button onClick={() => setShowCreate(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}
      <ChatroomList
        rooms={rooms}
        selectedId={current ? current.id : null}
        onSelect={setCurrent}
        onCreate={createRoom}
      />
      <div className="chat-window">
        <h1>{current ? current.name : 'Select a chatroom'}</h1>
        {current && <MessageList messages={messages} />}
        {current && <MessageInput onSend={sendMessage} user={user} />}
      </div>
      <MemberList members={members} />
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
