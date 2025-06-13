const UserBanner = ({ user, avatar, onEdit }) => {
  const style = avatar
    ? { backgroundImage: `url(${avatar})`, backgroundSize: 'cover' }
    : {};
  return (
    <div className="user-banner">
      <div className="avatar-placeholder" style={style} />
      <span className="user-banner-name">{user}</span>
      <button className="edit-profile-icon" onClick={onEdit}>
        &#9881;
      </button>
    </div>
  );
};
