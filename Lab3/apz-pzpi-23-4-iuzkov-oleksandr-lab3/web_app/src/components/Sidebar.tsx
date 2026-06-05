import { Link } from 'react-router-dom';
import { LocaleCode } from '../types';
import { t } from '../i18n';

interface SidebarProps {
  locale: LocaleCode;
  isAdmin: boolean;
}

export default function Sidebar({ locale, isAdmin }: SidebarProps) {
  return (
    <aside className="sidebar">
      <nav>
        <ul>
          {!isAdmin ? (
            <>
              <li>
                <Link to="/dashboard">{t(locale, 'dashboard')}</Link>
              </li>
              <li>
                <Link to="/sensors">{t(locale, 'sensors')}</Link>
              </li>
              <li>
                <Link to="/rooms">{t(locale, 'rooms')}</Link>
              </li>
              <li>
                <Link to="/devices">{t(locale, 'devices')}</Link>
              </li>
              <li>
                <Link to="/alerts">{t(locale, 'alerts')}</Link>
              </li>
              <li>
                <Link to="/profile">{t(locale, 'profile')}</Link>
              </li>
              <li>
                <Link to="/settings">{t(locale, 'settings')}</Link>
              </li>
              <li>
                <Link to="/thresholds">{t(locale, 'thresholds')}</Link>
              </li>
            </>
          ) : (
            <>
              <li>
                <Link to="/admin">{t(locale, 'adminPanel')}</Link>
              </li>
              <li>
                <Link to="/admin/users">{t(locale, 'usersManagement')}</Link>
              </li>
              <li>
                <Link to="/admin/system">{t(locale, 'systemSettings')}</Link>
              </li>
              <li>
                <Link to="/admin/logs">{t(locale, 'systemLogs')}</Link>
              </li>
            </>
          )}
        </ul>
      </nav>
    </aside>
  );
}

