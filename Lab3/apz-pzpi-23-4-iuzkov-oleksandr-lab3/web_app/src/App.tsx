import { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { LocaleCode, UserProfile } from './types';
import { t, getDirection } from './i18n';
import { login, register, fetchProfile, setToken, getToken, clearToken } from './api';
import Sidebar from './components/Sidebar';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import SensorsPage from './pages/SensorsPage';
import SensorEditPage from './pages/SensorEditPage';
import RoomsPage from './pages/RoomsPage';
import RoomFormPage from './pages/RoomFormPage';
import DevicesPage from './pages/DevicesPage';
import DeviceEditPage from './pages/DeviceEditPage';
import DeviceCreatePage from './pages/DeviceCreatePage';
import AlertsPage from './pages/AlertsPage';
import ProfilePage from './pages/ProfilePage';
import SettingsPage from './pages/SettingsPage';
import ThresholdsPage from './pages/ThresholdsPage';
import SensorCreatePage from './pages/SensorCreatePage';
import AdminDashboardPage from './pages/AdminDashboardPage';
import AdminUsersPage from './pages/AdminUsersPage';
import AdminSystemPage from './pages/AdminSystemPage';
import AdminLogsPage from './pages/AdminLogsPage';

function App() {
  const savedLocale = (localStorage.getItem('locale') as LocaleCode) || 'en';
  const [locale, setLocaleState] = useState<LocaleCode>(savedLocale);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);
  const navigate = useNavigate();

  const direction = getDirection(locale);
  const token = getToken();

  useEffect(() => {
    if (token && !profile) {
      setAuthLoading(true);
      fetchProfile(token)
        .then(setProfile)
        .catch(() => {
          clearToken();
          setProfile(null);
        })
        .finally(() => setAuthLoading(false));
    }
  }, [token, profile]);

  useEffect(() => {

    try {
      document.documentElement.lang = locale;
      document.documentElement.dir = direction;
    } catch {

    }
    localStorage.setItem('locale', locale);
  }, [locale, direction]);

  const handleLogin = async (email: string, password: string) => {
    try {
      setLoading(true);
      setLoginError('');
      const data = await login(email, password);
      setToken(data.access_token);
      const user = await fetchProfile(data.access_token);
      setProfile(user);
      navigate(user.is_admin ? '/admin' : '/dashboard');
    } catch {
      setLoginError(t(locale, 'loginFailed'));
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (username: string, email: string, password: string) => {
    try {
      setLoading(true);
      setLoginError('');
      await register(username, email, password);
      const data = await login(email, password);
      setToken(data.access_token);
      const user = await fetchProfile(data.access_token);
      setProfile(user);
      navigate(user.is_admin ? '/admin' : '/dashboard');
    } catch (err: any) {
      const msg = err.response?.data?.detail || t(locale, 'createUserFailed');
      setLoginError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    clearToken();
    setProfile(null);
    navigate('/login');
  };

  if (token && !profile && authLoading) {
    return (
      <div className="app-shell" dir={direction}>
        <header className="app-header">
          <h1>{t(locale, 'appTitle')}</h1>
        </header>
        <main className="app-content">
          <div className="card">{t(locale, 'loading')}</div>
        </main>
      </div>
    );
  }

  return (
    <div className="app-shell" dir={direction}>
      <header className="app-header">
        <div>
          <h1>{t(locale, 'appTitle')}</h1>
          {profile && <div className="small-text">{profile.username} • {profile.is_admin ? t(locale, 'admin') : t(locale, 'user')}</div>}
        </div>
        <div className="header-actions">
          <select value={locale} onChange={(event) => setLocaleState(event.target.value as LocaleCode)}>
            <option value="en">{t(locale, 'english')}</option>
            <option value="uk">{t(locale, 'ukrainian')}</option>
          </select>
          {profile && (
            <button className="secondary" onClick={handleLogout}>{t(locale, 'logout')}</button>
          )}
        </div>
      </header>

      {profile ? (
        <div className="app-body">
          <Sidebar locale={locale} isAdmin={profile.is_admin} />
          <main className="app-content">
            <Routes>
                <Route path="/" element={<Navigate to={profile?.is_admin ? '/admin' : '/dashboard'} replace />} />
              <Route path="/dashboard" element={<UserProtected profile={profile} locale={locale}><DashboardPage locale={locale} /></UserProtected>} />
              <Route path="/sensors" element={<UserProtected profile={profile} locale={locale}><SensorsPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/sensors/create" element={<UserProtected profile={profile} locale={locale}><SensorCreatePage locale={locale} token={token} /></UserProtected>} />
              <Route path="/sensors/edit/:id" element={<UserProtected profile={profile} locale={locale}><SensorEditPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/rooms" element={<UserProtected profile={profile} locale={locale}><RoomsPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/rooms/create" element={<UserProtected profile={profile} locale={locale}><RoomFormPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/rooms/edit/:id" element={<UserProtected profile={profile} locale={locale}><RoomFormPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/devices" element={<UserProtected profile={profile} locale={locale}><DevicesPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/devices/create" element={<UserProtected profile={profile} locale={locale}><DeviceCreatePage locale={locale} token={token} /></UserProtected>} />
              <Route path="/devices/edit/:id" element={<UserProtected profile={profile} locale={locale}><DeviceEditPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/alerts" element={<UserProtected profile={profile} locale={locale}><AlertsPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/profile" element={<UserProtected profile={profile} locale={locale}><ProfilePage locale={locale} profile={profile} token={token} /></UserProtected>} />
              <Route path="/settings" element={<UserProtected profile={profile} locale={locale}><SettingsPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/thresholds" element={<UserProtected profile={profile} locale={locale}><ThresholdsPage locale={locale} token={token} /></UserProtected>} />
              <Route path="/admin" element={<AdminProtected profile={profile} locale={locale}><AdminDashboardPage locale={locale} /></AdminProtected>} />
              <Route path="/admin/users" element={<AdminProtected profile={profile} locale={locale}><AdminUsersPage locale={locale} token={token} /></AdminProtected>} />
              <Route path="/admin/system" element={<AdminProtected profile={profile} locale={locale}><AdminSystemPage locale={locale} token={token} /></AdminProtected>} />
              <Route path="/admin/logs" element={<AdminProtected profile={profile} locale={locale}><AdminLogsPage locale={locale} token={token} /></AdminProtected>} />
              <Route path="*" element={<Navigate to={profile?.is_admin ? '/admin' : '/dashboard'} replace />} />
            </Routes>
          </main>
        </div>
      ) : (
        <main className="app-content app-guest">
          <Routes>
            <Route path="/login" element={<LoginPage locale={locale} onLogin={handleLogin} onRegister={handleRegister} loading={loading} error={loginError} />} />
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        </main>
      )}
    </div>
  );
}

function AdminProtected({ profile, children, locale }: { profile: UserProfile | null; children: React.ReactNode; locale: LocaleCode }) {
  if (!profile) return <Navigate to="/login" replace />;
  if (!profile.is_admin) return <div className="card"><p>{t(locale, 'adminOnly')}</p></div>;
  return <>{children}</>;
}

function UserProtected({ profile, children, locale }: { profile: UserProfile | null; children: React.ReactNode; locale: LocaleCode }) {
  if (!profile) return <Navigate to="/login" replace />;
  if (profile.is_admin) return <Navigate to="/admin" replace />;
  return <>{children}</>;
}

export default App;

