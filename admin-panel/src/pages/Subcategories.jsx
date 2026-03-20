import { useEffect, useState } from 'react';
import api from '../api/axios';
import styles from './Table.module.css';

const SERVER_URL = 'http://localhost:3000';
const imgUrl = (p) => p ? `${SERVER_URL}${p.startsWith('/') ? p : `/${p}`}` : '';
const empty = { name: '', icon: '', categoryId: '', isActive: true, order: 0 };

export default function Subcategories() {
  const [subcategories, setSubcategories] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterCat, setFilterCat] = useState('');
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(empty);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const [catRes, subRes] = await Promise.all([
        api.get('/categories'),
        api.get(filterCat ? `/subcategories?categoryId=${filterCat}` : '/subcategories'),
      ]);
      setCategories(catRes.data);
      setSubcategories(subRes.data);
    } catch {
      setError('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [filterCat]);

  const openAdd = () => {
    setForm({ ...empty, categoryId: categories[0]?._id || '' });
    setImageFile(null);
    setImagePreview('');
    setModal('add');
    setError('');
  };

  const openEdit = (sub) => {
    setForm({
      name: sub.name,
      icon: sub.icon,
      categoryId: sub.category?._id || sub.category,
      isActive: sub.isActive,
      order: sub.order ?? 0,
    });
    setImageFile(null);
    setImagePreview(sub.image ? imgUrl(sub.image) : '');
    setModal(sub);
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
    if (!form.name.trim() || !form.categoryId) return;
    setSaving(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('name', form.name);
      fd.append('icon', form.icon);
      fd.append('categoryId', form.categoryId);
      fd.append('order', form.order);
      fd.append('isActive', form.isActive);
      if (imageFile) fd.append('image', imageFile);

      if (modal === 'add') {
        await api.post('/subcategories', fd);
      } else {
        await api.put(`/subcategories/${modal._id}`, fd);
      }
      closeModal();
      load();
    } catch (err) {
      setError(err.response?.data?.message || 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (sub) => {
    if (!window.confirm(`Delete "${sub.name}"?`)) return;
    try {
      await api.delete(`/subcategories/${sub._id}`);
      load();
    } catch { alert('Delete failed'); }
  };

  const toggleActive = async (sub) => {
    try {
      const fd = new FormData();
      fd.append('name', sub.name);
      fd.append('icon', sub.icon);
      fd.append('categoryId', sub.category?._id || sub.category);
      fd.append('order', sub.order ?? 0);
      fd.append('isActive', !sub.isActive);
      await api.put(`/subcategories/${sub._id}`, fd);
      load();
    } catch { alert('Update failed'); }
  };

  return (
    <div>
      <div className={styles.header}>
        <h2 className={styles.title}>Subcategories</h2>
        <div className={styles.headerRight}>
          <select
            className={styles.filterSelect}
            value={filterCat}
            onChange={(e) => setFilterCat(e.target.value)}
          >
            <option value="">All Categories</option>
            {categories.map((c) => (
              <option key={c._id} value={c._id}>{c.name}</option>
            ))}
          </select>
          <button className={styles.addBtn} onClick={openAdd}>+ Add Subcategory</button>
        </div>
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
                <th>Category</th>
                <th>Order</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {subcategories.length === 0 && (
                <tr><td colSpan={8} className={styles.empty}>No subcategories yet</td></tr>
              )}
              {subcategories.map((sub) => (
                <tr key={sub._id}>
                  <td>
                    {sub.image
                      ? <img src={imgUrl(sub.image)} alt={sub.name} className={styles.thumb} />
                      : <span className={styles.noImg}>—</span>}
                  </td>
                  <td className={styles.iconCell}>{sub.icon || '—'}</td>
                  <td className={styles.nameCell}>{sub.name}</td>
                  <td>{sub.category?.name || '—'}</td>
                  <td>{sub.order ?? 0}</td>
                  <td>
                    <span
                      className={sub.isActive ? styles.badgeActive : styles.badgeInactive}
                      onClick={() => toggleActive(sub)}
                      title="Click to toggle"
                      style={{ cursor: 'pointer' }}
                    >
                      {sub.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>{new Date(sub.createdAt).toLocaleDateString()}</td>
                  <td className={styles.actions}>
                    <button className={styles.editBtn} onClick={() => openEdit(sub)}>Edit</button>
                    <button className={styles.deleteBtn} onClick={() => handleDelete(sub)}>Delete</button>
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
            <h3>{modal === 'add' ? 'Add Subcategory' : 'Edit Subcategory'}</h3>
            {error && <div className={styles.formError}>{error}</div>}
            <form onSubmit={handleSave} className={styles.form}>
              <label>Category *</label>
              <select
                value={form.categoryId}
                onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
                required
              >
                <option value="">Select category</option>
                {categories.map((c) => (
                  <option key={c._id} value={c._id}>{c.name}</option>
                ))}
              </select>
              <label>Name *</label>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="e.g. Smartphones"
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
