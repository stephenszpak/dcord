const MessageList = ({ messages }) => (
  <div className="messages">
    {messages.map((m, idx) => (
      <div key={idx} className="message">
        <strong>{m.user}</strong>: {m.content}
      </div>
    ))}
  </div>
);
