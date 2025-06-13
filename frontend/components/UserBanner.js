const UserBanner = ({ user, onEdit }) => {
  return (
    <div className="user-banner">
      <div className="avatar-placeholder" />
      <span className="user-banner-name">{user}</span>
      <button className="edit-profile-icon" onClick={onEdit}>
        &#9881;
      </button>
    </div>
  );
};
