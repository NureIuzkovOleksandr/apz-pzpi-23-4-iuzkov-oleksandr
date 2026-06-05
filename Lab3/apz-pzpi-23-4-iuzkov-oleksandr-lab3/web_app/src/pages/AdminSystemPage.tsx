import { useState, ChangeEvent } from 'react';
import { LocaleCode } from '../types';
import { t } from '../i18n';
import { cleanupData, exportConfiguration, importConfiguration } from '../api';

interface AdminSystemPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function AdminSystemPage({ locale, token }: AdminSystemPageProps) {
  const [status, setStatus] = useState('');
  const [importResult, setImportResult] = useState('');
  const [daysToKeep, setDaysToKeep] = useState(90);

  const handleExport = async () => {
    if (!token) return;
    const config = await exportConfiguration(token);
    const blob = new Blob([JSON.stringify(config, null, 2)], { type: 'application/json' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'configuration.json';
    link.click();
    setStatus(t(locale, 'exportSuccess'));
  };

  const handleCleanup = async () => {
    if (!token) return;
    await cleanupData(token, daysToKeep);
    setStatus(t(locale, 'cleanupSuccess'));
  };

  const handleImport = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !token) return;
    try {
      const text = await file.text();
      const configData = JSON.parse(text);
      await importConfiguration(token, configData);
      setImportResult(t(locale, 'importSuccess'));
    } catch {
      setImportResult(t(locale, 'importFailed'));
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'systemSettings')}</span></nav>
      <div className="card">
        <h3>{t(locale, 'exportConfiguration')}</h3>
        <p>{t(locale, 'exportConfigurationDescription')}</p>
        <button onClick={handleExport}>{t(locale, 'download')}</button>
      </div>
      <div className="card">
        <h3>{t(locale, 'cleanupOldData')}</h3>
        <p>{t(locale, 'cleanupOldDataDescription')}</p>
        <label>
          {t(locale, 'daysToKeep')}:
          <input
            type="number"
            min={1}
            value={daysToKeep}
            onChange={(event) => setDaysToKeep(Number(event.target.value))}
          />
        </label>
        <button onClick={handleCleanup}>{t(locale, 'cleanupOldData')}</button>
      </div>
      <div className="card">
        <h3>{t(locale, 'importConfiguration')}</h3>
        <p>{t(locale, 'importConfigurationDescription')}</p>
        <input type="file" accept="application/json" onChange={handleImport} />
        {importResult && <div>{importResult}</div>}
      </div>
      {status && <div className="status">{status}</div>}
    </div>
  );
}

