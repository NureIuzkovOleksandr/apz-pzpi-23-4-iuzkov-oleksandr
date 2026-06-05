import { FormEvent, useEffect, useState } from 'react';
import { LocaleCode } from '../types';
import { t } from '../i18n';

interface SettingsPageProps {
  locale: LocaleCode;
  token: string | null;
}

const settingKey = 'web_app_settings';

type SettingsState = {
  dateFormat: 'short' | 'medium' | 'long';
  notificationsEnabled: boolean;
};

const defaultSettings: SettingsState = {
  dateFormat: 'medium',
  notificationsEnabled: true,
};

export default function SettingsPage({ locale, token }: SettingsPageProps) {
  const [settings, setSettings] = useState<SettingsState>(defaultSettings);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const stored = window.localStorage.getItem(settingKey);
    if (stored) {
      try {
        setSettings(JSON.parse(stored));
      } catch {
        setSettings(defaultSettings);
      }
    }
  }, []);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    window.localStorage.setItem(settingKey, JSON.stringify(settings));
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'settings')}</span></nav>
      <div className="card">
        <h3>{t(locale, 'dateFormat')}</h3>
        <p>{t(locale, 'settingsDescription')}</p>
        <form onSubmit={handleSubmit}>
          <label>
            {t(locale, 'dateFormat')}
            <select value={settings.dateFormat} onChange={(event) => setSettings({ ...settings, dateFormat: event.target.value as any })}>
              <option value="short">Short</option>
              <option value="medium">Medium</option>
              <option value="long">Long</option>
            </select>
          </label>
          <label>
            <input
              type="checkbox"
              checked={settings.notificationsEnabled}
              onChange={(event) => setSettings({ ...settings, notificationsEnabled: event.target.checked })}
            />
            {t(locale, 'notificationsEnabled')}
          </label>
          <button type="submit" className="button primary">{t(locale, 'save')}</button>
          {saved && <span className="small-text">{t(locale, 'settingsSaved')}</span>}
        </form>
      </div>
    </div>
  );
}

