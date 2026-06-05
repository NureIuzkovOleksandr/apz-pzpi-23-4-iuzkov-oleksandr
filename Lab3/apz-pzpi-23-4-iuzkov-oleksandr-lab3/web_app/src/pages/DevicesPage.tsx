import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { LocaleCode, ClimateDevice, Room } from '../types';
import { t } from '../i18n';
import { fetchDevices, fetchRooms } from '../api';

interface DevicesPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function DevicesPage({ locale, token }: DevicesPageProps) {
  const [devices, setDevices] = useState<ClimateDevice[]>([]);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);

    Promise.all([fetchDevices(token), fetchRooms(token)])
      .then(([deviceData, roomData]) => {
        setDevices(deviceData);
        setRooms(roomData);
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  const roomMap = new Map(rooms.map((room) => [room.id, room.name]));

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'devices')}</span></nav>
      <div className="card">
        <div className="card-actions">
          <Link to="/devices/create" className="button primary">{t(locale, 'createDevice')}</Link>
        </div>
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <table>
          <thead>
            <tr>
              <th>{t(locale, 'deviceName')}</th>
              <th>{t(locale, 'deviceType')}</th>
              <th>{t(locale, 'room')}</th>
              <th>{t(locale, 'status')}</th>
              <th>{t(locale, 'actions')}</th>
            </tr>
          </thead>
          <tbody>
            {devices.map((device) => (
              <tr key={device.id}>
                <td>{device.name}</td>
                <td>{device.device_type}</td>
                <td>{roomMap.get(device.room_id) ?? `${t(locale, 'roomId')}: ${device.room_id}`}</td>
                <td>{device.status}</td>
                <td>
                  <Link to={`/devices/edit/${device.id}`} className="button secondary">
                    {t(locale, 'edit')}
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

