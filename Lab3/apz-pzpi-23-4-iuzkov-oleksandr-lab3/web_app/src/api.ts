import axios from 'axios';
import {
  UserProfile,
  UserTableItem,
  Sensor,
  Room,
  RoomCreateRequest,
  SensorCreateRequest,
  DeviceCreateRequest,
  ClimateDevice,
  Alert,
  ApiMetrics,
  LoadTestResult,
} from './types';

const baseUrl = 'http://127.0.0.1:8000';

const api = axios.create({
  baseURL: baseUrl,
  headers: {
    'Content-Type': 'application/json',
  },
});

function authHeaders(token: string | null) {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function login(email: string, password: string) {
  const response = await api.post('/api/auth/login', { email, password });
  return response.data as { access_token: string };
}

export async function register(username: string, email: string, password: string) {
  const response = await api.post('/api/users/register', { username, email, password });
  return response.data;
}

export async function fetchProfile(token: string): Promise<UserProfile> {
  const response = await api.get('/api/users/me', { headers: authHeaders(token) });
  return response.data as UserProfile;
}

export async function fetchRooms(token: string): Promise<Room[]> {
  const response = await api.get('/api/rooms', { headers: authHeaders(token) });
  return response.data as Room[];
}

export async function fetchRoom(token: string, roomId: number): Promise<Room> {
  const response = await api.get(`/api/rooms/${roomId}`, { headers: authHeaders(token) });
  return response.data as Room;
}

export async function createRoom(token: string, data: RoomCreateRequest): Promise<Room> {
  const response = await api.post('/api/rooms', data, { headers: authHeaders(token) });
  return response.data as Room;
}

export async function updateRoom(token: string, roomId: number, data: RoomCreateRequest): Promise<Room> {
  const response = await api.put(`/api/rooms/${roomId}`, data, { headers: authHeaders(token) });
  return response.data as Room;
}

export async function fetchSensor(token: string, sensorId: number): Promise<Sensor> {
  const response = await api.get(`/api/sensors/${sensorId}`, { headers: authHeaders(token) });
  return response.data as Sensor;
}

export async function fetchSensors(token: string): Promise<Sensor[]> {
  const response = await api.get('/api/sensors', { headers: authHeaders(token) });
  return response.data as Sensor[];
}

export async function updateSensor(token: string, sensorId: number, data: Partial<Pick<Sensor, 'name' | 'status'>>): Promise<Sensor> {
  const response = await api.put(`/api/sensors/${sensorId}`, data, { headers: authHeaders(token) });
  return response.data as Sensor;
}

export async function createSensor(token: string, data: SensorCreateRequest): Promise<Sensor> {
  const response = await api.post('/api/sensors', data, { headers: authHeaders(token) });
  return response.data as Sensor;
}

export async function fetchDevice(token: string, deviceId: number): Promise<ClimateDevice> {
  const response = await api.get(`/api/climate-devices/${deviceId}`, { headers: authHeaders(token) });
  return response.data as ClimateDevice;
}

export async function fetchDevices(token: string): Promise<ClimateDevice[]> {
  const response = await api.get('/api/climate-devices', { headers: authHeaders(token) });
  return response.data as ClimateDevice[];
}

export async function updateDevice(token: string, deviceId: number, data: Partial<Pick<ClimateDevice, 'name' | 'status' | 'power_consumption'>>): Promise<ClimateDevice> {
  const response = await api.put(`/api/climate-devices/${deviceId}`, data, { headers: authHeaders(token) });
  return response.data as ClimateDevice;
}

export async function createDevice(token: string, data: DeviceCreateRequest): Promise<ClimateDevice> {
  const response = await api.post('/api/climate-devices', data, { headers: authHeaders(token) });
  return response.data as ClimateDevice;
}

export async function updateProfile(token: string, data: Partial<Pick<UserProfile, 'username' | 'email'>> & { first_name?: string; last_name?: string; phone_number?: string }) {
  const response = await api.put('/api/users/me', data, { headers: authHeaders(token) });
  return response.data as UserProfile;
}

export async function fetchThresholdForRoom(token: string, roomId: number): Promise<any> {
  const response = await api.get(`/api/climate-thresholds/room/${roomId}`, { headers: authHeaders(token) });
  return response.data;
}

export async function createThreshold(token: string, data: { room_id: number; min_temperature?: number; max_temperature?: number; min_humidity?: number; max_humidity?: number; auto_control_enabled?: boolean }) {
  const response = await api.post('/api/climate-thresholds', data, { headers: authHeaders(token) });
  return response.data;
}

export async function updateRoomThreshold(token: string, roomId: number, data: { min_temperature?: number; max_temperature?: number; min_humidity?: number; max_humidity?: number; auto_control_enabled?: boolean }) {
  const response = await api.put(`/api/climate-thresholds/room/${roomId}`, data, { headers: authHeaders(token) });
  return response.data;
}

export async function fetchAlerts(token: string): Promise<Alert[]> {
  const response = await api.get('/api/alerts', { headers: authHeaders(token) });
  return response.data as Alert[];
}

export async function fetchMetrics(): Promise<ApiMetrics> {
  const response = await api.get('/metrics');
  return response.data as ApiMetrics;
}

export async function runLoadTest(intensity: number, durationSeconds: number): Promise<LoadTestResult> {
  const response = await api.post('/api/test/load', null, {
    params: {
      intensity,
      duration_seconds: durationSeconds,
    },
  });
  return response.data as LoadTestResult;
}

export async function fetchUsers(token: string): Promise<{ total: number; users: UserTableItem[] }> {
  const response = await api.get('/api/admin/users/list', { headers: authHeaders(token) });
  return response.data;
}

export async function deleteUser(token: string, userId: number) {
  const response = await api.post(
    '/api/admin/users/manage',
    { operation: 'delete', target_user_id: userId },
    { headers: authHeaders(token) }
  );
  return response.data;
}

export async function exportConfiguration(token: string) {
  const response = await api.get('/api/export/configuration', { headers: authHeaders(token) });
  return response.data;
}

export async function cleanupData(token: string, daysToKeep = 90) {
  const response = await api.post(
    '/api/admin/cleanup',
    { days_to_keep: daysToKeep },
    { headers: authHeaders(token) }
  );
  return response.data;
}

export async function importConfiguration(token: string, configuration: unknown) {
  const response = await api.post('/api/import/configuration', configuration, {
    headers: authHeaders(token),
  });
  return response.data;
}

export async function importUsers(token: string, users: UserTableItem[]) {
  const createResults = [];
  for (const user of users) {
    const response = await api.post(
      '/api/admin/users/manage',
      {
        operation: 'create',
        user_data: {
          username: user.username,
          email: user.email,
          is_admin: user.is_admin,
          is_active: user.is_active,
        },
      },
      { headers: authHeaders(token) }
    );
    createResults.push(response.data);
  }
  return createResults;
}

export async function createUser(token: string, username: string, email: string, password: string, isAdmin = false) {
  const response = await api.post(
    '/api/admin/users/manage',
    {
      operation: 'create',
      user_data: {
        username,
        email,
        password,
        is_admin: isAdmin,
      },
    },
    { headers: authHeaders(token) }
  );
  return response.data;
}

export async function fetchSystemLogs(token: string, limit = 100, skip = 0): Promise<any> {
  const response = await api.get('/api/admin/system/logs', {
    params: { limit, skip },
    headers: authHeaders(token),
  });
  return response.data;
}

export async function exportUsers(users: UserTableItem[]) {
  return users;
}

export function setToken(token: string) {
  localStorage.setItem('access_token', token);
}

export function getToken() {
  return localStorage.getItem('access_token');
}

export function clearToken() {
  localStorage.removeItem('access_token');
}

