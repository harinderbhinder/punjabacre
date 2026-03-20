import { NavLink, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import styles from './Layout.module.css';

export default function Layout({ children }) {
  const navigate = useNavigate();
  const admin = JSON.parse(localStorage.getItem('admin') || '{}');

  const handleLogout = async () => {
    try {
      const refreshToken = localStorage.getItem('refreshToken');
      await api.post('/auth/logout', { refreshToken });
    } catch { /* ignore */ }
    localStorage.clear();
    navigate('/login');
  };

  return (
    <div className={styles.shell}>
      <aside className={styles.sidebar}>
        <div className={styles.logo}>
          <span>⚙️</span> Admin Panel
        </div>
        <nav className={styles.nav}>
          <NavLink to="/dashboard" className={({ isActive }) => isActive ? styles.active : ''}>
            🏠 Dashboard
          </NavLink>
          <NavLink to="/categories" className={({ isActive }) => isActive ? styles.active : ''}>
            📂 Categories
          </NavLink>
          <NavLink to="/subcategories" className={({ isActive }) => isActive ? styles.active : ''}>
            📋 Subcategories
          </NavLink>
          <NavLink to="/banners" className={({ isActive }) => isActive ? styles.active : ''}>
            🖼️ Banners
          </NavLink>
          <NavLink to="/ads" className={({ isActive }) => isActive ? styles.active : ''}>
            📢 Ads
          </NavLink>
        </nav>
        <div className={styles.userBox}>
          <div className={styles.userName}>{admin.name || 'Admin'}</div>
          <div className={styles.userEmail}>{admin.email}</div>
          <button className={styles.logoutBtn} onClick={handleLogout}>Logout</button>
        </div>
      </aside>
      <main className={styles.main}>{children}</main>
    </div>
  );
}
