const ChatApp = ({ user }) => {
  const [rooms, setRooms] = React.useState([]);
  const [current, setCurrent] = React.useState(null);
  const [messages, setMessages] = React.useState([]);
  const [members, setMembers] = React.useState([]);
  const [showCreate, setShowCreate] = React.useState(false);
  const [newRoomName, setNewRoomName] = React.useState('');

  const loadRooms = async () => {
    const data = await fetchChatrooms(user);
    setRooms(data);
    if (!current && data.length > 0) setCurrent(data[0]);
  };

  React.useEffect(loadRooms, []);

  const loadMessages = async () => {
    if (!current) return;
    const msgs = await fetchMessages(current.id);
    setMessages(msgs);
    const mems = await fetchMembers(current.id);
    setMembers(mems);
  };

  React.useEffect(loadMessages, [current]);

  const sendMessage = async (msg) => {
    if (!current) return;
    await postMessage(current.id, msg);
    loadMessages();
  };

  const createRoom = () => setShowCreate(true);

  const submitCreateRoom = async () => {
    if (!newRoomName) return;
    await createChatroom(newRoomName, user);
    setShowCreate(false);
    setNewRoomName('');
    loadRooms();
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
};
