const fetchChatrooms = async (user) => {
  const res = await fetch(`/chatrooms?user=${encodeURIComponent(user)}`);
  return res.json();
};

const fetchMessages = async (chatroomId) => {
  const res = await fetch(`/messages?chatroom_id=${chatroomId}`);
  return res.json();
};

const fetchMembers = async (chatroomId) => {
  const res = await fetch(`/members?chatroom_id=${chatroomId}`);
  return res.json();
};

const postMessage = async (chatroomId, msg) => {
  await fetch('/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...msg, chatroom_id: chatroomId }),
  });
};

const createChatroom = async (name, user) => {
  const res = await fetch('/chatrooms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, user }),
  });
  return res.json();
};

const login = async (username, password) => {
  const res = await fetch('/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  return res.ok;
};

const register = async (username, password) => {
  const res = await fetch('/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  return res.ok;
};
