import { useEffect, useMemo, useState } from 'react';
import { LocaleCode, UserTableItem } from '../types';
import { t, formatDate } from '../i18n';
import { deleteUser, fetchUsers, createUser, exportUsers } from '../api';

interface AdminUsersPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function AdminUsersPage({ locale, token }: AdminUsersPageProps) {
  const [users, setUsers] = useState<UserTableItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [sortBy, setSortBy] = useState<'username' | 'email' | 'created_at'>('username');
  const [searchText, setSearchText] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createForm, setCreateForm] = useState({ username: '', email: '', password: '', isAdmin: false });
  const [createLoading, setCreateLoading] = useState(false);
  const [createError, setCreateError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    fetchUsers(token)
      .then((data) => setUsers(data.users))
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  const filteredUsers = useMemo(() => {
    const searchLower = searchText.toLowerCase();
    return users.filter(
      (user) => user.username.toLowerCase().includes(searchLower) || user.email.toLowerCase().includes(searchLower)
    );
  }, [users, searchText]);

  const sortedUsers = useMemo(() => {
    const collator = new Intl.Collator(locale, { numeric: true });
    return [...filteredUsers].sort((a, b) => collator.compare(a[sortBy], b[sortBy]));
  }, [filteredUsers, sortBy, locale]);

  const removeUser = async (id: number) => {
    if (!token) return;
    setLoading(true);
    try {
      await deleteUser(token, id);
      setUsers((current) => current.filter((item) => item.id !== id));
    } catch {
      setError(t(locale, 'fetchFailed'));
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setCreateLoading(true);
    setCreateError('');
    try {
      await createUser(token, createForm.username, createForm.email, createForm.password, createForm.isAdmin);
      setCreateForm({ username: '', email: '', password: '', isAdmin: false });
      setShowCreateForm(false);
      const data = await fetchUsers(token);
      setUsers(data.users);
    } catch {
      setCreateError(t(locale, 'createUserFailed'));
    } finally {
      setCreateLoading(false);
    }
  };

  const handleExportUsers = () => {
    const data = JSON.stringify(sortedUsers, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `users_export_${new Date().toISOString().split('T')[0]}.json`;
    link.click();
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'usersManagement')}</span></nav>
      <div className="card">
        <div className="toolbar">
          <button onClick={() => setShowCreateForm(!showCreateForm)} className="primary">
            {showCreateForm ? t(locale, 'cancel') : t(locale, 'createUser')}
          </button>
          <button onClick={handleExportUsers} className="secondary">
            {t(locale, 'exportUsers')}
          </button>
        </div>
      </div>

      {showCreateForm && (
        <div className="card">
          <h3>{t(locale, 'createNewUser')}</h3>
          <form onSubmit={handleCreateUser}>
            <label>
              {t(locale, 'username')}
              <input
                type="text"
                required
                value={createForm.username}
                onChange={(e) => setCreateForm({ ...createForm, username: e.target.value })}
              />
            </label>
            <label>
              {t(locale, 'email')}
              <input
                type="email"
                required
                value={createForm.email}
                onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
              />
            </label>
            <label>
              {t(locale, 'password')}
              <input
                type="password"
                required
                value={createForm.password}
                onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
              />
            </label>
            <label>
              <input
                type="checkbox"
                checked={createForm.isAdmin}
                onChange={(e) => setCreateForm({ ...createForm, isAdmin: e.target.checked })}
              />
              {t(locale, 'makeAdmin')}
            </label>
            <button type="submit" disabled={createLoading}>
              {createLoading ? t(locale, 'loading') : t(locale, 'create')}
            </button>
            {createError && <div className="error">{createError}</div>}
          </form>
        </div>
      )}

      <div className="card">
        <div className="toolbar">
          <label>
            {t(locale, 'search')}:
            <input type="text" value={searchText} onChange={(e) => setSearchText(e.target.value)} placeholder="username, email" />
          </label>
          <label>
            {t(locale, 'sortBy')}:
            <select value={sortBy} onChange={(event) => setSortBy(event.target.value as any)}>
              <option value="username">{t(locale, 'username')}</option>
              <option value="email">{t(locale, 'email')}</option>
              <option value="created_at">{t(locale, 'createdAt')}</option>
            </select>
          </label>
        </div>
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        {sortedUsers.length === 0 && !loading && <div>{t(locale, 'noUsers')}</div>}
        {sortedUsers.length > 0 && (
          <table>
            <thead>
              <tr>
                <th>{t(locale, 'username')}</th>
                <th>{t(locale, 'email')}</th>
                <th>{t(locale, 'role')}</th>
                <th>{t(locale, 'createdAt')}</th>
                <th>{t(locale, 'actions')}</th>
              </tr>
            </thead>
            <tbody>
              {sortedUsers.map((user) => (
                <tr key={user.id}>
                  <td>{user.username}</td>
                  <td>{user.email}</td>
                  <td>{user.is_admin ? t(locale, 'admin') : t(locale, 'user')}</td>
                  <td>{formatDate(locale, user.created_at)}</td>
                  <td>
                    <button className="secondary" onClick={() => removeUser(user.id)}>
                      {t(locale, 'delete')}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

