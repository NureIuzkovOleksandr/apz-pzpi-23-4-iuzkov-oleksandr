import { useEffect, useState } from 'react';
import { LocaleCode } from '../types';
import { t, formatDate } from '../i18n';
import { fetchSystemLogs } from '../api';

interface AdminLogsPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function AdminLogsPage({ locale, token }: AdminLogsPageProps) {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [limit, setLimit] = useState(100);

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    fetchSystemLogs(token, limit, 0)
      .then((data) => setLogs(data.logs || []))
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token, limit]);

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'systemLogs')}</span></nav>
      <div className="card">
        <div className="toolbar">
          <label>
            {t(locale, 'recordsPerPage')}:
            <select value={limit} onChange={(event) => setLimit(Number(event.target.value))}>
              <option value={50}>50</option>
              <option value={100}>100</option>
              <option value={200}>200</option>
              <option value={500}>500</option>
            </select>
          </label>
        </div>
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        {logs.length === 0 && !loading && <div>{t(locale, 'noLogs')}</div>}
        {logs.length > 0 && (
          <table>
            <thead>
              <tr>
                <th>{t(locale, 'timestamp')}</th>
                <th>{t(locale, 'deviceType')}</th>
                <th>{t(locale, 'logLevel')}</th>
                <th>{t(locale, 'message')}</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log, idx) => (
                <tr key={idx}>
                  <td>{formatDate(locale, log.created_at || log.timestamp)}</td>
                  <td>{log.device_type}</td>
                  <td>
                    <span style={{ color: log.log_level === 'error' ? 'red' : log.log_level === 'warning' ? 'orange' : 'green' }}>
                      {log.log_level?.toUpperCase()}
                    </span>
                  </td>
                  <td>{log.message}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

