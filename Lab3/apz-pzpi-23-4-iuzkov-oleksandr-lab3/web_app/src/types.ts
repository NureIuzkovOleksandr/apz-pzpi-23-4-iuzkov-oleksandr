export type LocaleCode = 'en' | 'uk';

export interface UserProfile {
  id: number;
  username: string;
  email: string;
  is_admin: boolean;
  is_active: boolean;
  created_at: string;
}

export interface UserTableItem {
  id: number;
  username: string;
  email: string;
  is_admin: boolean;
  is_active: boolean;
  created_at: string;
}

export interface Sensor {
  id: number;
  name: string;
  sensor_type: string;
  status: string;
  room_id: number;
  room_name?: string;
  created_at: string;
}

export interface Room {
  id: number;
  name: string;
  description?: string;
  floor?: string;
  area?: number;
  created_at: string;
}

export interface RoomCreateRequest {
  name: string;
  description?: string;
  floor?: number;
  area?: number;
}

export interface SensorCreateRequest {
  name: string;
  device_id: string;
  sensor_type: string;
  room_id: number;
}

export interface DeviceCreateRequest {
  name: string;
  device_id: string;
  device_type: string;
  room_id: number;
  power_consumption?: number;
}

export interface ClimateDevice {
  id: number;
  name: string;
  device_type: string;
  status: string;
  room_id: number;
  room_name?: string;
  power_consumption?: number;
  created_at: string;
}

export interface Alert {
  id: number;
  alert_type: string;
  message: string;
  severity: string;
  is_read: boolean;
  created_at: string;
}

export interface ApiMetrics {
  total_requests: number;
  total_errors: number;
  uptime_seconds: number;
  requests_per_second: number;
  pod_name: string;
  timestamp: string;
}

export interface LoadTestResult {
  status: string;
  elapsed_seconds: number;
  intensity: number;
  work_units: number;
  server_pod: string;
  requests_per_second: number;
}

