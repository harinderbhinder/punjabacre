import { useEffect, useState, useCallback } from 'react';
import api from '../api/axios';
import styles from './Table.module.css';

const SERVER_URL = 'http://localhost:3000';
const imgUrl = (p) => p ? `${SERVER_URL}${p.startsWith('/') ? p : `/${p}`}` : '';

export default function Ads() {
  const [ads, setAds]         = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage]       = useState(1);
  const [pages, setPages]     = useState(1);
  const [total, setTotal]     = useState(0);
  const [search, setSearch]   = useState('');
  const [filter, setFilter]   = useState('all'); // all | pending | active | inactive

  const load = useCallback(async (p = page) => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: p, limit: 20 });
      if (search) params.set('q', search);
      if (filter === 'pending')  params.set('isApproved', 'false');
      if (filter === 'active')   params.set('isActive', 'true');
      if (filter === 'inactive') params.set('isActive', 'false');
      const { data } = await api.get(`/ads/admin/all?${params}`);
      setAds(data.ads);
      setTotal(data.total);
      setPages(data.pages);
      setPage(p);
    } catch {
      alert('Failed to load ads');
    } finally {
      setLoading(false);
    }
  }, [page, search, filter]);

  useEffect(() => { load(1); }, [search, filter]); // eslint-disable-line

  const toggle = async (ad) => {
    try {
      await api.patch(`/ads/admin/${ad._id}/toggle`);
      load(page);
    } catch { alert('Failed'); }
  };

  const approve = async (ad, action) => {
    try {
      await api.patch(`/ads/admin/${ad._id}/approve`, { action });
      load(page);
    } catch { alert('Failed'); }
  };

  const remove = async (ad) => {
    if (!window.confirm(`Delete "${ad.title}"? This cannot be undone.`)) return;
    try {
      await api.delete(`/ads/admin/${ad._id}`);
      load(page);
    } catch { alert('Delete failed'); }
  };

  return (
    <div>
      <div className={styles.header}>
        <h2 className={styles.title}>Ads <span style={{ fontSize: 14, color: '#888', fontWeight: 400 }}>({total})</span></h2>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
        <input
          className={styles.searchInput}
          placeholder="Search title or brand..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        {['all', 'pending', 'active', 'inactive'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={filter === f ? styles.filterBtnActive : styles.filterBtn}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {loading ? (
        <div className={styles.center}>Loading...</div>
      ) : (
        <>
          <div className={styles.tableWrap}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Image</th>
                  <th>Title</th>
                  <th>Price</th>
                  <th>Category</th>
                  <th>Posted By</th>
                  <th>Status</th>
                  <th>Approved</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {ads.length === 0 && (
                  <tr><td colSpan={9} className={styles.empty}>No ads found</td></tr>
                )}
                {ads.map((ad) => (
                  <tr key={ad._id}>
                    <td>
                      {ad.images?.[0]
                        ? <img src={imgUrl(ad.images[0])} alt={ad.title} className={styles.thumb} />
                        : <span className={styles.noImg}>—</span>}
                    </td>
                    <td className={styles.nameCell} title={ad.title}>{ad.title}</td>
                    <td>₹{Number(ad.price).toLocaleString()}</td>
                    <td>{ad.category?.name || '—'}</td>
                    <td style={{ fontSize: 12 }}>
                      <div>{ad.user?.name || '—'}</div>
                      <div style={{ color: '#aaa' }}>{ad.user?.email || ''}</div>
                    </td>
                    <td>
                      <span
                        className={ad.isActive ? styles.badgeActive : styles.badgeInactive}
                        onClick={() => toggle(ad)}
                        title="Click to toggle"
                        style={{ cursor: 'pointer' }}
                      >
                        {ad.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      {(!ad.approvalStatus || ad.approvalStatus === 'pending') ? (
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button className={styles.approveBtn} onClick={() => approve(ad, 'approve')}>Approve</button>
                          <button className={styles.disapproveBtn} onClick={() => approve(ad, 'disapprove')}>Disapprove</button>
                        </div>
                      ) : (
                        <span className={ad.approvalStatus === 'approved' ? styles.badgeActive : styles.badgeInactive}>
                          {ad.approvalStatus === 'approved' ? 'Approved' : 'Disapproved'}
                        </span>
                      )}
                    </td>
                    <td style={{ fontSize: 12 }}>{new Date(ad.createdAt).toLocaleDateString()}</td>
                    <td className={styles.actions}>
                      <button className={styles.deleteBtn} onClick={() => remove(ad)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {pages > 1 && (
            <div style={{ display: 'flex', gap: 8, marginTop: 16, justifyContent: 'center' }}>
              <button className={styles.filterBtn} disabled={page <= 1} onClick={() => load(page - 1)}>← Prev</button>
              <span style={{ lineHeight: '32px', fontSize: 13 }}>Page {page} of {pages}</span>
              <button className={styles.filterBtn} disabled={page >= pages} onClick={() => load(page + 1)}>Next →</button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
