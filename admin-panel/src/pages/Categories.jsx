import { useEffect, useState } from 'react';
import api from '../api/axios';
import styles from './Table.module.css';

const SERVER_URL = 'http://localhost:3000';
const imgUrl = (p) => p ? `${SERVER_URL}${p.startsWith('/') ? p : `/${p}`}` : '';
const empty = { name: '', icon: '', isActive: true, order: 0 };

export default function Categories() {
  const [categories, setCategories] = useState([]);
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
      const { data } = await api.get('/categories');
      setCategories(data);
    } catch {
      setError('Failed to load categories');
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

  const openEdit = (cat) => {
    setForm({ name: cat.name, icon: cat.icon, isActive: cat.isActive, order: cat.order ?? 0 });
    setImageFile(null);
    setImagePreview(cat.image ? imgUrl(cat.image) : '');
    setModal(cat);
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
    if (!form.name.trim()) return;
    setSaving(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('name', form.name);
      fd.append('icon', form.icon);
      fd.append('order', form.order);
      fd.append('isActive', form.isActive);
      if (imageFile) fd.append('image', imageFile);

      if (modal === 'add') {
        await api.post('/categories', fd);
      } else {
        await api.put(`/categories/${modal._id}`, fd);
      }
      closeModal();
      load();
    } catch (err) {
      setError(err.response?.data?.message || 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (cat) => {
    if (!window.confirm(`Delete "${cat.name}"? All its subcategories will also be deleted.`)) return;
    try {
      await api.delete(`/categories/${cat._id}`);
      load();
    } catch { alert('Delete failed'); }
  };

  const toggleActive = async (cat) => {
    try {
      const fd = new FormData();
      fd.append('name', cat.name);
      fd.append('icon', cat.icon);
      fd.append('order', cat.order ?? 0);
      fd.append('isActive', !cat.isActive);
      await api.put(`/categories/${cat._id}`, fd);
      load();
    } catch { alert('Update failed'); }
  };

  return (
    <div>
      <div className={styles.header}>
        <h2 className={styles.title}>Categories</h2>
        <button className={styles.addBtn} onClick={openAdd}>+ Add Category</button>
      </div>

      {loading ? (
        <div className={styles.center}>Loading...</div>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Image</th>
                <th>Icon</th>
                <th>Name</th>
                <th>Order</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {categories.length === 0 && (
                <tr><td colSpan={7} className={styles.empty}>No categories yet</td></tr>
              )}
              {categories.map((cat) => (
                <tr key={cat._id}>
                  <td>
                    {cat.image
                      ? <img src={imgUrl(cat.image)} alt={cat.name} className={styles.thumb} />
                      : <span className={styles.noImg}>—</span>}
                  </td>
                  <td className={styles.iconCell}>{cat.icon || '—'}</td>
                  <td className={styles.nameCell}>{cat.name}</td>
                  <td>{cat.order ?? 0}</td>
                  <td>
                    <span
                      className={cat.isActive ? styles.badgeActive : styles.badgeInactive}
                      onClick={() => toggleActive(cat)}
                      title="Click to toggle"
                      style={{ cursor: 'pointer' }}
                    >
                      {cat.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>{new Date(cat.createdAt).toLocaleDateString()}</td>
                  <td className={styles.actions}>
                    <button className={styles.editBtn} onClick={() => openEdit(cat)}>Edit</button>
                    <button className={styles.deleteBtn} onClick={() => handleDelete(cat)}>Delete</button>
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
            <h3>{modal === 'add' ? 'Add Category' : 'Edit Category'}</h3>
            {error && <div className={styles.formError}>{error}</div>}
            <form onSubmit={handleSave} className={styles.form}>
              <label>Name *</label>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="e.g. Electronics"
                required
              />
              <label>Icon (emoji)</label>
              <input
                value={form.icon}
                onChange={(e) => setForm({ ...form, icon: e.target.value })}
                placeholder="e.g. 📱"
              />
              <label>Order</label>
              <input
                type="number"
                value={form.order}
                onChange={(e) => setForm({ ...form, order: parseInt(e.target.value) || 0 })}
                placeholder="0"
                min="0"
              />
              <label>Image (jpg/png/webp, max 2MB)</label>
              <input type="file" accept="image/jpeg,image/png,image/webp" onChange={handleImageChange} />
              {imagePreview && (
                <img src={imagePreview} alt="preview" className={styles.previewImg} />
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
