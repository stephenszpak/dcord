const RegisterForm = ({ onRegister, onShowLogin }) => {
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [verify, setVerify] = React.useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (password !== verify) {
      alert('Passwords do not match');
      return;
    }
    if (await register(username, password)) {
      onRegister(username);
    } else {
      alert('Error creating account');
    }
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
};
