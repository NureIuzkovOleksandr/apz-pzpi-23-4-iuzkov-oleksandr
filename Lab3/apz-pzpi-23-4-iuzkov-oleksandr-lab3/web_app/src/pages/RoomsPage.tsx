import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { LocaleCode, Room } from '../types';
import { t } from '../i18n';
import { fetchRooms } from '../api';

interface RoomsPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function RoomsPage({ locale, token }: RoomsPageProps) {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    fetchRooms(token)
      .then(setRooms)
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'rooms')}</span></nav>
      <div className="card">
        <div className="card-actions">
          <Link to="/rooms/create" className="button primary">{t(locale, 'createRoom')}</Link>
        </div>
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <table>
          <thead>
            <tr>
              <th>{t(locale, 'roomName')}</th>
              <th>{t(locale, 'description')}</th>
              <th>{t(locale, 'floor')}</th>
              <th>{t(locale, 'area')}</th>
              <th>{t(locale, 'actions')}</th>
            </tr>
          </thead>
          <tbody>
            {rooms.map((room) => (
              <tr key={room.id}>
                <td>{room.name}</td>
                <td>{room.description}</td>
                <td>{room.floor}</td>
                <td>{room.area}</td>
                <td>
                  <Link to={`/rooms/edit/${room.id}`} className="button secondary">{t(locale, 'edit')}</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

