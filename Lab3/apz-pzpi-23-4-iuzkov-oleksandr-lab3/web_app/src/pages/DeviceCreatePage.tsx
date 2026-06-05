import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { LocaleCode, Room, DeviceCreateRequest } from '../types';
import { t } from '../i18n';
import { createDevice, fetchRooms } from '../api';

interface DeviceCreatePageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function DeviceCreatePage({ locale, token }: DeviceCreatePageProps) {
  const navigate = useNavigate();
  const [rooms, setRooms] = useState<Room[]>([]);
  const [name, setName] = useState('');
  const [deviceId, setDeviceId] = useState('');
  const [deviceType, setDeviceType] = useState('heater');
  const [roomId, setRoomId] = useState<string>('');
  const [powerConsumption, setPowerConsumption] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    fetchRooms(token)
      .then((data) => {
        setRooms(data);
        if (data.length > 0) setRoomId(data[0].id.toString());
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

    const generateIdFromName = (n: string) => n.trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || `device_${Date.now()}`;
    const finalDeviceId = deviceId.trim() || generateIdFromName(name);
    setSaving(true);
    setError('');

    const payload: DeviceCreateRequest = {
      name,
      device_id: finalDeviceId,
      device_type: deviceType,
      room_id: Number(roomId),
      power_consumption: powerConsumption ? Number(powerConsumption) : undefined,
    };

    try {
      await createDevice(token, payload);
      navigate('/devices');
    } catch {
      setError(t(locale, 'saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'createDevice')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <label>
            {t(locale, 'deviceName')}
            <input value={name} onChange={(event) => setName(event.target.value)} />
          </label>
          <input type="hidden" value={deviceId} />
          <label>
            {t(locale, 'deviceType')}
            <select value={deviceType} onChange={(event) => setDeviceType(event.target.value)}>
              <option value="air_conditioner">Air Conditioner</option>
              <option value="heater">Heater</option>
              <option value="humidifier">Humidifier</option>
              <option value="dehumidifier">Dehumidifier</option>
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
          <label>
            {t(locale, 'powerConsumption')}
            <input
              type="number"
              min="0"
              step="0.1"
              value={powerConsumption}
              onChange={(event) => setPowerConsumption(event.target.value)}
            />
          </label>
          <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
          <Link to="/devices" className="button secondary">{t(locale, 'backToList')}</Link>
        </form>
      </div>
    </div>
  );
}

