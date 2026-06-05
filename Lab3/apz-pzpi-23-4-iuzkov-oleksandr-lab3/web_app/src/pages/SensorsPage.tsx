import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { LocaleCode, Room, Sensor } from '../types';
import { t } from '../i18n';
import { fetchRooms, fetchSensors } from '../api';

interface SensorsPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function SensorsPage({ locale, token }: SensorsPageProps) {
  const [sensors, setSensors] = useState<Sensor[]>([]);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);

    Promise.all([fetchSensors(token), fetchRooms(token)])
      .then(([sensorData, roomData]) => {
        setSensors(sensorData);
        setRooms(roomData);
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  const roomMap = new Map(rooms.map((room) => [room.id, room.name]));

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'sensors')}</span></nav>
      <div className="card">
        <div className="card-actions">
          <Link to="/sensors/create" className="button primary">{t(locale, 'createSensor')}</Link>
        </div>
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <table>
          <thead>
            <tr>
              <th>{t(locale, 'sensorName')}</th>
              <th>{t(locale, 'sensorType')}</th>
              <th>{t(locale, 'room')}</th>
              <th>{t(locale, 'status')}</th>
              <th>{t(locale, 'actions')}</th>
            </tr>
          </thead>
          <tbody>
            {sensors.map((sensor) => (
              <tr key={sensor.id}>
                <td>{sensor.name}</td>
                <td>{sensor.sensor_type}</td>
                <td>{roomMap.get(sensor.room_id) ?? `${t(locale, 'roomId')}: ${sensor.room_id}`}</td>
                <td>{sensor.status}</td>
                <td>
                  <Link to={`/sensors/edit/${sensor.id}`} className="button secondary">
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

