const MemberList = ({ members }) => (
  <div className="members">
    <div className="chatrooms-header">Members</div>
    {members.map((m) => (
      <div key={m.username} className="member" style={{ opacity: m.online ? 1 : 0.5 }}>
        {m.username}
      </div>
    ))}
  </div>
);
