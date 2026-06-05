import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { LocaleCode, Room, SensorCreateRequest, ClimateDevice } from '../types';
import { t } from '../i18n';
import { createSensor, fetchRooms, fetchDevices } from '../api';

interface SensorCreatePageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function SensorCreatePage({ locale, token }: SensorCreatePageProps) {
  const navigate = useNavigate();
  const [rooms, setRooms] = useState<Room[]>([]);
  const [name, setName] = useState('');
  const [deviceId, setDeviceId] = useState('');
  const [devices, setDevices] = useState<ClimateDevice[]>([]);
  const [sensorType, setSensorType] = useState('temperature');
  const [roomId, setRoomId] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    Promise.all([fetchRooms(token), fetchDevices(token)])
      .then(([roomData, deviceData]) => {
        setRooms(roomData);
        setDevices(deviceData);
        if (roomData.length > 0) setRoomId(roomData[0].id.toString());
        if (deviceData.length > 0) setDeviceId(deviceData[0].id.toString());
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token || !roomId) return;
    if (!name.trim()) {
      setError(t(locale, 'requiredField'));
      return;
    }
     if (!deviceId.trim()) {
       setError('Device ID is required');
       return;
     }
     setSaving(true);
     setError('');

    const payload: SensorCreateRequest = {
      name,
      device_id: deviceId,
      sensor_type: sensorType,
      room_id: Number(roomId),
    };

    try {
      await createSensor(token, payload);
      navigate('/sensors');
    } catch {
      setError(t(locale, 'saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'createSensor')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <label>
            {t(locale, 'sensorName')}
            <input value={name} onChange={(event) => setName(event.target.value)} />
          </label>
          <label>
            {t(locale, 'device') || 'Device'}
            <select value={deviceId} onChange={(event) => setDeviceId(event.target.value)}>
              {devices.length === 0 ? (
                <option value="">{t(locale, 'noDevices') || 'No devices'}</option>
              ) : (
                devices.map((d) => (
                  <option key={d.id} value={d.id.toString()}>{d.name}</option>
                ))
              )}
            </select>
          </label>
          <label>
            {t(locale, 'sensorType')}
            <select value={sensorType} onChange={(event) => setSensorType(event.target.value)}>
              <option value="temperature">Temperature</option>
              <option value="humidity">Humidity</option>
              <option value="combined">Combined</option>
            </select>
          </label>
          <label>
            {t(locale, 'room')}
            <select value={roomId} onChange={(event) => setRoomId(event.target.value)}>
              {rooms.map((room) => (
                <option key={room.id} value={room.id.toString()}>{room.name}</option>
              ))}
            </select>
          </label>
          <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
          <Link to="/sensors" className="button secondary">{t(locale, 'backToList')}</Link>
        </form>
      </div>
    </div>
  );
}

