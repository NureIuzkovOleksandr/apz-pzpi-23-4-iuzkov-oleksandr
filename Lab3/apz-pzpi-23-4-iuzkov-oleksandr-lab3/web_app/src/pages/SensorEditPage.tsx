import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { LocaleCode, Room, Sensor } from '../types';
import { t } from '../i18n';
import { fetchRooms, fetchSensor, updateSensor } from '../api';

interface SensorEditPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function SensorEditPage({ locale, token }: SensorEditPageProps) {
  const { id } = useParams<{ id: string }>();
  const sensorId = Number(id);
  const navigate = useNavigate();
  const [sensor, setSensor] = useState<Sensor | null>(null);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [name, setName] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token || Number.isNaN(sensorId)) return;
    setLoading(true);

    Promise.all([fetchSensor(token, sensorId), fetchRooms(token)])
      .then(([sensorData, roomData]) => {
        setSensor(sensorData);
        setName(sensorData.name);
        setStatus(sensorData.status);
        setRooms(roomData);
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token, sensorId]);

  const roomName = rooms.find((room) => room.id === sensor?.room_id)?.name;

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token || !sensor) return;
    setSaving(true);
    setError('');

    try {
      await updateSensor(token, sensorId, { name, status });
      navigate('/sensors');
    } catch {
      setError(t(locale, 'fetchFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'edit')} {t(locale, 'sensorName')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        {sensor && (
          <form onSubmit={handleSubmit}>
            <label>
              {t(locale, 'sensorName')}
              <input value={name} onChange={(event) => setName(event.target.value)} />
            </label>
            <label>
              {t(locale, 'sensorType')}
              <input value={sensor.sensor_type} disabled />
            </label>
            <label>
              {t(locale, 'room')}
              <input value={roomName ?? `${t(locale, 'roomId')}: ${sensor.room_id}`} disabled />
            </label>
            <label>
              {t(locale, 'status')}
              <select value={status} onChange={(event) => setStatus(event.target.value)}>
                <option value="active">{t(locale, 'active')}</option>
                <option value="inactive">{t(locale, 'inactive')}</option>
                <option value="error">Error</option>
              </select>
            </label>
            <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
            <Link to="/sensors" className="button secondary">{t(locale, 'backToList')}</Link>
          </form>
        )}
      </div>
    </div>
  );
}

