import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { LocaleCode, Room, ClimateDevice } from '../types';
import { t } from '../i18n';
import { fetchDevice, fetchRooms, updateDevice } from '../api';

interface DeviceEditPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function DeviceEditPage({ locale, token }: DeviceEditPageProps) {
  const { id } = useParams<{ id: string }>();
  const deviceId = Number(id);
  const navigate = useNavigate();
  const [device, setDevice] = useState<ClimateDevice | null>(null);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [name, setName] = useState('');
  const [status, setStatus] = useState('');
  const [powerConsumption, setPowerConsumption] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token || Number.isNaN(deviceId)) return;
    setLoading(true);

    Promise.all([fetchDevice(token, deviceId), fetchRooms(token)])
      .then(([deviceData, roomData]) => {
        setDevice(deviceData);
        setName(deviceData.name);
        setStatus(deviceData.status);
        setPowerConsumption(deviceData.power_consumption?.toString() ?? '');
        setRooms(roomData);
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token, deviceId]);

  const roomName = rooms.find((room) => room.id === device?.room_id)?.name;

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token || !device) return;
    setSaving(true);
    setError('');

    try {
      await updateDevice(token, deviceId, {
        name,
        status,
        power_consumption: powerConsumption ? Number(powerConsumption) : undefined,
      });
      navigate('/devices');
    } catch {
      setError(t(locale, 'fetchFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'edit')} {t(locale, 'deviceName')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        {device && (
          <form onSubmit={handleSubmit}>
            <label>
              {t(locale, 'deviceName')}
              <input value={name} onChange={(event) => setName(event.target.value)} />
            </label>
            <label>
              {t(locale, 'deviceType')}
              <input value={device.device_type} disabled />
            </label>
            <label>
              {t(locale, 'room')}
              <input value={roomName ?? `${t(locale, 'roomId')}: ${device.room_id}`} disabled />
            </label>
            <label>
              {t(locale, 'status')}
              <select value={status} onChange={(event) => setStatus(event.target.value)}>
                <option value="on">On</option>
                <option value="off">Off</option>
                <option value="error">Error</option>
              </select>
            </label>
            <label>
              {t(locale, 'powerConsumption')}
              <input
                type="number"
                value={powerConsumption}
                onChange={(event) => setPowerConsumption(event.target.value)}
                min="0"
                step="0.1"
              />
            </label>
            <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
            <Link to="/devices" className="button secondary">{t(locale, 'backToList')}</Link>
          </form>
        )}
      </div>
    </div>
  );
}

