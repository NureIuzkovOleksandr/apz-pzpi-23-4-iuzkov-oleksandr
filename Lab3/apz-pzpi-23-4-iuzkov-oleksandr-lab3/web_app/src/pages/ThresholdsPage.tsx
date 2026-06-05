import { FormEvent, useEffect, useState } from 'react';
import { LocaleCode, Room } from '../types';
import { t } from '../i18n';
import { createThreshold, fetchRooms, fetchThresholdForRoom, updateRoomThreshold } from '../api';

interface ThresholdsPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function ThresholdsPage({ locale, token }: ThresholdsPageProps) {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [selectedRoomId, setSelectedRoomId] = useState<number | null>(null);
  const [minTemperature, setMinTemperature] = useState('');
  const [maxTemperature, setMaxTemperature] = useState('');
  const [minHumidity, setMinHumidity] = useState('');
  const [maxHumidity, setMaxHumidity] = useState('');
  const [autoControl, setAutoControl] = useState(false);
  const [thresholdLoading, setThresholdLoading] = useState(false);
  const [thresholdSaving, setThresholdSaving] = useState(false);
  const [thresholdError, setThresholdError] = useState('');
  const [thresholdMessage, setThresholdMessage] = useState('');
  const [thresholdExists, setThresholdExists] = useState(false);

  useEffect(() => {
    if (!token) return;
    fetchRooms(token)
      .then((data) => {
        setRooms(data);
        if (data.length > 0) setSelectedRoomId(data[0].id);
      })
      .catch(() => {
        setThresholdError(t(locale, 'fetchFailed'));
      });
  }, [locale, token]);

  useEffect(() => {
    if (!token || selectedRoomId === null) return;
    setThresholdLoading(true);
    setThresholdError('');
    fetchThresholdForRoom(token, selectedRoomId)
      .then((threshold) => {
        setThresholdExists(true);
        setMinTemperature(threshold.min_temperature?.toString() ?? '');
        setMaxTemperature(threshold.max_temperature?.toString() ?? '');
        setMinHumidity(threshold.min_humidity?.toString() ?? '');
        setMaxHumidity(threshold.max_humidity?.toString() ?? '');
        setAutoControl(Boolean(threshold.auto_control_enabled));
      })
      .catch(() => {
        setThresholdExists(false);
        setMinTemperature('');
        setMaxTemperature('');
        setMinHumidity('');
        setMaxHumidity('');
        setAutoControl(false);
      })
      .finally(() => setThresholdLoading(false));
  }, [locale, token, selectedRoomId]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token || selectedRoomId === null) return;
    setThresholdSaving(true);
    setThresholdError('');
    setThresholdMessage('');

    const payload = {
      room_id: selectedRoomId,
      min_temperature: minTemperature ? Number(minTemperature) : undefined,
      max_temperature: maxTemperature ? Number(maxTemperature) : undefined,
      min_humidity: minHumidity ? Number(minHumidity) : undefined,
      max_humidity: maxHumidity ? Number(maxHumidity) : undefined,
      auto_control_enabled: autoControl,
    };

    try {
      if (thresholdExists) {
        await updateRoomThreshold(token, selectedRoomId, payload);
      } else {
        await createThreshold(token, payload);
        setThresholdExists(true);
      }
      setThresholdMessage(t(locale, 'thresholdSaved'));
    } catch {
      setThresholdError(t(locale, 'saveFailed'));
    } finally {
      setThresholdSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{t(locale, 'thresholds')}</span></nav>
      <div className="card">
        {thresholdError && <div className="error">{thresholdError}</div>}
        <form onSubmit={handleSubmit}>
          <label>
            {t(locale, 'room')}
            <select value={selectedRoomId ?? ''} onChange={(event) => setSelectedRoomId(Number(event.target.value))}>
              {rooms.map((room) => (
                <option key={room.id} value={room.id}>{room.name}</option>
              ))}
            </select>
          </label>
          <label>
            {t(locale, 'minTemperature')}
            <input type="number" value={minTemperature} onChange={(event) => setMinTemperature(event.target.value)} step="0.1" />
          </label>
          <label>
            {t(locale, 'maxTemperature')}
            <input type="number" value={maxTemperature} onChange={(event) => setMaxTemperature(event.target.value)} step="0.1" />
          </label>
          <label>
            {t(locale, 'minHumidity')}
            <input type="number" value={minHumidity} onChange={(event) => setMinHumidity(event.target.value)} step="0.1" />
          </label>
          <label>
            {t(locale, 'maxHumidity')}
            <input type="number" value={maxHumidity} onChange={(event) => setMaxHumidity(event.target.value)} step="0.1" />
          </label>
          <label>
            <input type="checkbox" checked={autoControl} onChange={(event) => setAutoControl(event.target.checked)} />
            {t(locale, 'autoControlEnabled')}
          </label>
          {thresholdLoading && <p>{t(locale, 'loading')}</p>}
          {thresholdMessage && <div className="success">{thresholdMessage}</div>}
          <button type="submit" className="button primary" disabled={thresholdSaving || thresholdLoading}>
            {thresholdExists ? t(locale, 'save') : t(locale, 'create')}
          </button>
        </form>
      </div>
    </div>
  );
}

