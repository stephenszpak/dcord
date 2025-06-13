const App = () => {
  const [user, setUser] = React.useState(null);
  const [showRegister, setShowRegister] = React.useState(false);

  if (!user) {
    return showRegister ? (
      <RegisterForm onRegister={setUser} onShowLogin={() => setShowRegister(false)} />
    ) : (
      <LoginForm onLogin={setUser} onShowRegister={() => setShowRegister(true)} />
    );
  }

  return <ChatApp user={user} />;
};

ReactDOM.render(<App />, document.getElementById('root'));
