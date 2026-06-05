import { FormEvent, useState } from 'react';
import { LocaleCode, UserProfile } from '../types';
import { t, formatDate } from '../i18n';
import { updateProfile } from '../api';

interface ProfilePageProps {
  locale: LocaleCode;
  profile: UserProfile | null;
  token: string | null;
}

export default function ProfilePage({ locale, profile, token }: ProfilePageProps) {
  const [editMode, setEditMode] = useState(false);
  const [username, setUsername] = useState(profile?.username ?? '');
  const [email, setEmail] = useState(profile?.email ?? '');
  const [phone, setPhone] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token) return;
    setSaving(true);
    setError('');
    setSuccess('');

    try {
      await updateProfile(token, {
        username,
        email,
        phone_number: phone,
        first_name: firstName,
        last_name: lastName,
      });
      setSuccess(t(locale, 'profileSaved'));
      setEditMode(false);
    } catch {
      setError(t(locale, 'saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'profile')}</span></nav>
      <div className="card">
        {!editMode ? (
          <>
            <h2>{profile?.username}</h2>
            <p>{t(locale, 'email')}: {profile?.email}</p>
            <p>{t(locale, 'role')}: {profile?.is_admin ? t(locale, 'admin') : t(locale, 'user')}</p>
            <p>{t(locale, 'createdAt')}: {profile ? formatDate(locale, profile.created_at) : '-'}</p>
            <button className="button primary" onClick={() => setEditMode(true)}>{t(locale, 'editProfile')}</button>
          </>
        ) : (
          <form onSubmit={handleSubmit}>
            <label>
              {t(locale, 'username')}
              <input value={username} onChange={(event) => setUsername(event.target.value)} />
            </label>
            <label>
              {t(locale, 'email')}
              <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
            </label>
            <label>
              {t(locale, 'firstName')}
              <input value={firstName} onChange={(event) => setFirstName(event.target.value)} />
            </label>
            <label>
              {t(locale, 'lastName')}
              <input value={lastName} onChange={(event) => setLastName(event.target.value)} />
            </label>
            <label>
              {t(locale, 'phoneNumber')}
              <input value={phone} onChange={(event) => setPhone(event.target.value)} />
            </label>
            {error && <div className="error">{error}</div>}
            {success && <div className="success">{success}</div>}
            <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
            <button type="button" className="button secondary" onClick={() => setEditMode(false)}>{t(locale, 'cancel')}</button>
          </form>
        )}
      </div>
    </div>
  );
}

