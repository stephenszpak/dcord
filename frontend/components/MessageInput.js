const MessageInput = ({ onSend, user }) => {
  const [content, setContent] = React.useState('');

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
      <button type="submit" className="send-button">&#8593;</button>
    </form>
  );
};
