const ChatroomList = ({ rooms, selectedId, onSelect, onCreate }) => (
  <div className="chatrooms">
    <div className="chatrooms-header">
      <span>Chatrooms</span>
      <button className="create-chatroom-icon" onClick={onCreate}>+</button>
    </div>
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
