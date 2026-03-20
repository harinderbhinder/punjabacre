import { useEffect, useState } from 'react';
import api from '../api/axios';
import styles from './Table.module.css';

const SERVER_URL = 'http://localhost:3000';

function imgUrl(p) {
  if (!p) return '';
  const clean = p.startsWith('/') ? p : `/${p}`;
  return `${SERVER_URL}${clean}`;
}
const empty = { title: '', subtitle: '', buttonText: 'Shop Now', order: 0, isActive: true };

export default function Banners() {
  const [banners, setBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(empty);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await api.get('/banners');
      setBanners(res.data?.data ?? res.data ?? []);
    } catch {
      setError('Failed to load banners');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const openAdd = () => {
    setForm(empty);
    setImageFile(null);
    setImagePreview('');
    setModal('add');
    setError('');
  };

  const openEdit = (b) => {
    setForm({
      title: b.title,
      subtitle: b.subtitle,
      buttonText: b.buttonText,
      order: b.order ?? 0,
      isActive: b.isActive,
    });
    setImageFile(null);
    setImagePreview(b.image ? imgUrl(b.image) : '');
    setModal(b);
    setError('');
  };

  const closeModal = () => { setModal(null); setImageFile(null); setImagePreview(''); };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('title', form.title);
      fd.append('subtitle', form.subtitle);
      fd.append('buttonText', form.buttonText);
      fd.append('order', form.order);
      fd.append('isActive', form.isActive);
      if (imageFile) fd.append('image', imageFile);

      if (modal === 'add') {
        await api.post('/banners', fd);
      } else {
        await api.put(`/banners/${modal._id}`, fd);
      }
      closeModal();
      load();
    } catch (err) {
      setError(err.response?.data?.message || 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (b) => {
    if (!window.confirm(`Delete banner "${b.title || 'this banner'}"?`)) return;
    try {
      await api.delete(`/banners/${b._id}`);
      load();
    } catch { alert('Delete failed'); }
  };

  const toggleActive = async (b) => {
    try {
      const fd = new FormData();
      fd.append('title', b.title);
      fd.append('subtitle', b.subtitle);
      fd.append('buttonText', b.buttonText);
      fd.append('order', b.order ?? 0);
      fd.append('isActive', !b.isActive);
      await api.put(`/banners/${b._id}`, fd);
      load();
    } catch { alert('Update failed'); }
  };

  return (
    <div>
      <div className={styles.header}>
        <h2 className={styles.title}>Promotional Banners</h2>
        <button className={styles.addBtn} onClick={openAdd}>+ Add Banner</button>
      </div>

      {loading ? (
        <div className={styles.center}>Loading...</div>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Image</th>
                <th>Title</th>
                <th>Subtitle</th>
                <th>Button</th>
                <th>Order</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {banners.length === 0 && (
                <tr><td colSpan={7} className={styles.empty}>No banners yet</td></tr>
              )}
              {banners.map((b) => (
                <tr key={b._id}>
                  <td>
                    {b.image
                      ? <img src={imgUrl(b.image)} alt={b.title} className={styles.bannerThumb} />
                      : <span className={styles.noImg}>No image</span>}
                  </td>
                  <td className={styles.nameCell}>{b.title || '—'}</td>
                  <td>{b.subtitle || '—'}</td>
                  <td>{b.buttonText || '—'}</td>
                  <td>{b.order ?? 0}</td>
                  <td>
                    <span
                      className={b.isActive ? styles.badgeActive : styles.badgeInactive}
                      onClick={() => toggleActive(b)}
                      title="Click to toggle"
                      style={{ cursor: 'pointer' }}
                    >
                      {b.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className={styles.actions}>
                    <button className={styles.editBtn} onClick={() => openEdit(b)}>Edit</button>
                    <button className={styles.deleteBtn} onClick={() => handleDelete(b)}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal && (
        <div className={styles.overlay} onClick={closeModal}>
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <h3>{modal === 'add' ? 'Add Banner' : 'Edit Banner'}</h3>
            {error && <div className={styles.formError}>{error}</div>}
            <form onSubmit={handleSave} className={styles.form}>
              <label>Title</label>
              <input
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="e.g. Sale Upto 20% Off"
              />
              <label>Subtitle</label>
              <input
                value={form.subtitle}
                onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
                placeholder="e.g. 2025 Collection"
              />
              <label>Button Text</label>
              <input
                value={form.buttonText}
                onChange={(e) => setForm({ ...form, buttonText: e.target.value })}
                placeholder="e.g. Shop Now"
              />
              <label>Order</label>
              <input
                type="number"
                value={form.order}
                onChange={(e) => setForm({ ...form, order: parseInt(e.target.value) || 0 })}
                min="0"
              />
              <label>Banner Image (recommended 1200×400)</label>
              <input type="file" accept="image/jpeg,image/png,image/webp" onChange={handleImageChange} />
              {imagePreview && (
                <img src={imagePreview} alt="preview" className={styles.bannerPreview} />
              )}
              {modal !== 'add' && (
                <label className={styles.checkLabel}>
                  <input
                    type="checkbox"
                    checked={form.isActive}
                    onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
                  />
                  Active
                </label>
              )}
              <div className={styles.modalActions}>
                <button type="button" className={styles.cancelBtn} onClick={closeModal}>Cancel</button>
                <button type="submit" className={styles.saveBtn} disabled={saving}>
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
