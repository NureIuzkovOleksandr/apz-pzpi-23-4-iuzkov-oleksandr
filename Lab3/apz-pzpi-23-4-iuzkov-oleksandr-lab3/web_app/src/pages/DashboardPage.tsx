import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Alert, LocaleCode } from '../types';
import { t, formatDate } from '../i18n';
import { fetchAlerts, fetchDevices, fetchRooms, fetchSensors, getToken, clearToken } from '../api';

interface DashboardPageProps {
  locale: LocaleCode;
}

export default function DashboardPage({ locale }: DashboardPageProps) {
  const [rooms, setRooms] = useState(0);
  const [sensors, setSensors] = useState(0);
  const [devices, setDevices] = useState(0);
  const [alerts, setAlerts] = useState(0);
  const [latestAlerts, setLatestAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const token = getToken();
    if (!token) {
      setError(t(locale, 'fetchFailed'));
      setLoading(false);
      return;
    }

    setLoading(true);
    Promise.all([fetchRooms(token), fetchSensors(token), fetchDevices(token), fetchAlerts(token)])
      .then(([roomsData, sensorsData, devicesData, alertsData]) => {
        setRooms(roomsData.length);
        setSensors(sensorsData.length);
        setDevices(devicesData.length);
        setAlerts(alertsData.length);
        const sorted = [...alertsData].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
        setLatestAlerts(sorted.slice(0, 4));
      })
      .catch((err) => {
        const status = err?.response?.status;
        if (status === 401) {
          clearToken();
          navigate('/login');
          return;
        }
        setError(t(locale, 'fetchFailed'));
      })
      .finally(() => setLoading(false));
  }, [locale, navigate]);

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'dashboard')}</span></nav>
      {error && <div className="error">{error}</div>}

      <div className="vertical-actions">
        <Link to="/rooms" className="quick-card quick-rooms">
          <strong>{t(locale, 'rooms')}</strong>
          <span>{t(locale, 'manageRooms')}</span>
        </Link>
        <Link to="/sensors" className="quick-card quick-sensors">
          <strong>{t(locale, 'sensors')}</strong>
          <span>{t(locale, 'manageSensors')}</span>
        </Link>
        <Link to="/devices" className="quick-card quick-devices">
          <strong>{t(locale, 'devices')}</strong>
          <span>{t(locale, 'manageDevices')}</span>
        </Link>
      </div>

      <div className="grid dashboard-grid">
        <div className="stat-card">
          <span>{t(locale, 'rooms')}</span>
          <strong>{loading ? '…' : rooms}</strong>
        </div>
        <div className="stat-card">
          <span>{t(locale, 'sensors')}</span>
          <strong>{loading ? '…' : sensors}</strong>
        </div>
        <div className="stat-card">
          <span>{t(locale, 'devices')}</span>
          <strong>{loading ? '…' : devices}</strong>
        </div>
        <div className="stat-card">
          <span>{t(locale, 'alerts')}</span>
          <strong>{loading ? '…' : alerts}</strong>
        </div>
      </div>

      <div className="card alert-panel">
        <div className="panel-header">
          <h3>{t(locale, 'activeAlerts')}</h3>
          <span>{loading ? t(locale, 'loading') : `${alerts} ${t(locale, 'alerts')}`}</span>
        </div>
        {loading ? (
          <p>{t(locale, 'loading')}</p>
        ) : latestAlerts.length === 0 ? (
          <p>{t(locale, 'noAlerts')}</p>
        ) : (
          <ul className="alert-list">
            {latestAlerts.map((alert) => (
              <li key={alert.id}>
                <strong>{alert.alert_type}</strong>
                <span>{alert.message}</span>
                <small>{formatDate(locale, alert.created_at)}</small>
              </li>
            ))}
          </ul>
        )}
      </div>

    </div>
  );
}

