import { useNavigate } from 'react-router-dom';
import styles from './Dashboard.module.css';

const cards = [
  { icon: '📂', label: 'Categories', path: '/categories', color: '#6c63ff' },
  { icon: '📋', label: 'Subcategories', path: '/subcategories', color: '#43b89c' },
];

export default function Dashboard() {
  const navigate = useNavigate();
  const admin = JSON.parse(localStorage.getItem('admin') || '{}');

  return (
    <div>
      <h2 className={styles.welcome}>Welcome back, {admin.name || 'Admin'} 👋</h2>
      <div className={styles.grid}>
        {cards.map((c) => (
          <div
            key={c.path}
            className={styles.card}
            style={{ background: c.color }}
            onClick={() => navigate(c.path)}
          >
            <span className={styles.cardIcon}>{c.icon}</span>
            <span className={styles.cardLabel}>{c.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
