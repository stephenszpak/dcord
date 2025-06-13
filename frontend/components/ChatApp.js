const ChatApp = ({ user }) => {
  const [rooms, setRooms] = React.useState([]);
  const [current, setCurrent] = React.useState(null);
  const [messages, setMessages] = React.useState([]);
  const [members, setMembers] = React.useState([]);
  const [showCreate, setShowCreate] = React.useState(false);
  const [showEdit, setShowEdit] = React.useState(false);
  const [newRoomName, setNewRoomName] = React.useState('');
  const [dialogDims, setDialogDims] = React.useState({ width: 0, height: 0 });
  const chatWindowRef = React.useRef(null);

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

  React.useLayoutEffect(() => {
    if ((showCreate || showEdit) && chatWindowRef.current) {
      const rect = chatWindowRef.current.getBoundingClientRect();
      setDialogDims({ width: rect.width - 15, height: rect.height - 15 });
    }
  }, [showCreate, showEdit, current]);

  return (
    <div className="chat-app">
      {showCreate && (
        <div className="dialog-backdrop">
          <div className="dialog" style={{ width: dialogDims.width, height: dialogDims.height }}>
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
      {showEdit && (
        <div className="dialog-backdrop">
          <div className="dialog" style={{ width: dialogDims.width, height: dialogDims.height }}>
            <h2>Edit Profile</h2>
            <div>
              <button onClick={() => setShowEdit(false)}>Close</button>
            </div>
          </div>
        </div>
      )}
      <div className="left-column">
        <ChatroomList
          rooms={rooms}
          selectedId={current ? current.id : null}
          onSelect={setCurrent}
          onCreate={createRoom}
        />
        <UserBanner user={user} onEdit={() => setShowEdit(true)} />
      </div>
      <div className="chat-window" ref={chatWindowRef}>
        <h1>{current ? current.name : 'Select a chatroom'}</h1>
        {current && <MessageList messages={messages} />}
        {current && <MessageInput onSend={sendMessage} user={user} />}
      </div>
      <MemberList members={members} />
    </div>
  );
};
