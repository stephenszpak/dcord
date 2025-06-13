const LoginForm = ({ onLogin, onShowRegister }) => {
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (await login(username, password)) {
      onLogin(username);
    } else {
      alert('Invalid credentials');
    }
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
};
