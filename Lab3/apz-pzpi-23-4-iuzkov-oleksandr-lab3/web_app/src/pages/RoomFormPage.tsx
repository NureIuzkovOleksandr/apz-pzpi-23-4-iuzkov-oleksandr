import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { LocaleCode, Room } from '../types';
import { t } from '../i18n';
import { createRoom, fetchRoom, updateRoom } from '../api';

interface RoomFormPageProps {
  locale: LocaleCode;
  token: string | null;
}

export default function RoomFormPage({ locale, token }: RoomFormPageProps) {
  const { id } = useParams<{ id: string }>();
  const roomId = id ? Number(id) : null;
  const navigate = useNavigate();
  const [room, setRoom] = useState<Room | null>(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [floor, setFloor] = useState('');
  const [area, setArea] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const editMode = roomId !== null;

  useEffect(() => {
    if (!token || !editMode) return;
    setLoading(true);
    fetchRoom(token, roomId!)
      .then((roomData) => {
        setRoom(roomData);
        setName(roomData.name);
        setDescription(roomData.description ?? '');
        setFloor(roomData.floor?.toString() ?? '');
        setArea(roomData.area?.toString() ?? '');
      })
      .catch(() => setError(t(locale, 'fetchFailed')))
      .finally(() => setLoading(false));
  }, [locale, token, editMode, roomId]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token) return;
    setSaving(true);
    setError('');

    const roomPayload = {
      name,
      description,
      floor: floor ? Number(floor) : undefined,
      area: area ? Number(area) : undefined,
    };

    try {
      if (editMode) {
        await updateRoom(token, roomId!, roomPayload);
      } else {
        await createRoom(token, roomPayload);
      }
      navigate('/rooms');
    } catch {
      setError(t(locale, 'saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <nav className="breadcrumb"><span>{editMode ? t(locale, 'editRoom') : t(locale, 'createRoom')}</span></nav>
      <div className="card">
        {loading && <div>{t(locale, 'loading')}</div>}
        {error && <div className="error">{error}</div>}
        <form onSubmit={handleSubmit}>
          <label>
            {t(locale, 'roomName')}
            <input value={name} onChange={(event) => setName(event.target.value)} />
          </label>
          <label>
            {t(locale, 'description')}
            <input value={description} onChange={(event) => setDescription(event.target.value)} />
          </label>
          <label>
            {t(locale, 'floor')}
            <input type="number" value={floor} onChange={(event) => setFloor(event.target.value)} />
          </label>
          <label>
            {t(locale, 'area')}
            <input type="number" step="0.1" value={area} onChange={(event) => setArea(event.target.value)} />
          </label>
          <button type="submit" className="button primary" disabled={saving}>{t(locale, 'save')}</button>
          <Link to="/rooms" className="button secondary">{t(locale, 'backToList')}</Link>
        </form>
      </div>
    </div>
  );
}

