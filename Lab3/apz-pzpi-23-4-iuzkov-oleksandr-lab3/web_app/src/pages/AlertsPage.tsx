import { useEffect, useState } from 'react';
import { LocaleCode, Alert } from '../types';
import { t, formatDate } from '../i18n';
import { fetchAlerts } from '../api';

interface AlertsPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function AlertsPage({ locale, token }: AlertsPageProps) {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    fetchAlerts(token)
      .then(setAlerts)
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'alerts')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <table>
          <thead>
            <tr>
              <th>{t(locale, 'alertType')}</th>
              <th>{t(locale, 'message')}</th>
              <th>{t(locale, 'severity')}</th>
              <th>{t(locale, 'createdAt')}</th>
            </tr>
          </thead>
          <tbody>
            {alerts.map((alert) => (
              <tr key={alert.id}>
                <td>{alert.alert_type}</td>
                <td>{alert.message}</td>
                <td>{alert.severity}</td>
                <td>{formatDate(locale, alert.created_at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

