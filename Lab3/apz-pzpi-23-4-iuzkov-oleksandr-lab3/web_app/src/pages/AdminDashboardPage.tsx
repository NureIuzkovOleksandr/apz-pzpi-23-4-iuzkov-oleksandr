import { LocaleCode } from '../types';
import { t } from '../i18n';
import { Link } from 'react-router-dom';

interface AdminDashboardPageProps {
  locale: LocaleCode;
}

export default function AdminDashboardPage({ locale }: AdminDashboardPageProps) {
  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'adminPanel')}</span></nav>
      <div className="grid">
        <div className="card">
          <h3>{t(locale, 'usersManagement')}</h3>
          <p>{t(locale, 'manageUsersSummary')}</p>
          <Link to="/admin/users">{t(locale, 'manageUsers')}</Link>
        </div>
        <div className="card">
          <h3>{t(locale, 'systemSettings')}</h3>
          <p>{t(locale, 'manageSystemSummary')}</p>
          <Link to="/admin/system">{t(locale, 'systemSettings')}</Link>
        </div>
        <div className="card">
          <h3>{t(locale, 'systemLogs')}</h3>
          <p>{t(locale, 'viewSystemEvents')}</p>
          <Link to="/admin/logs">{t(locale, 'systemLogs')}</Link>
        </div>
      </div>
    </div>
  );
}

