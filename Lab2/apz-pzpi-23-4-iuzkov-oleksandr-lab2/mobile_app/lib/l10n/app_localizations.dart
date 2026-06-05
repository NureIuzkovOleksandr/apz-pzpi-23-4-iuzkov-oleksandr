import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Climate Monitor',
      'signIn': 'Sign in',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'createAccount': 'Create an account',
      'sensors': 'Sensors',
      'rooms': 'Rooms',
      'devices': 'Devices',
      'settings': 'Settings',
      'profile': 'Profile',
      'alerts': 'Alerts',
      'thresholds': 'Thresholds',
      'logout': 'Logout',
      'save': 'Save',
      'saveProfile': 'Save Profile',
      'saveRoom': 'Save Room',
      'saveSensor': 'Save Sensor',
      'saveDevice': 'Save Device',
      'addDevice': 'Add Device',
      'saveConnection': 'Save connection',
      'testConnection': 'Test connection',
      'connectionOk': 'Connection OK',
      'connectionFailed': 'Connection failed',
      'connectionSaved': 'Connection settings saved',
      'apiBaseUrl': 'API Base URL',
      'userProfile': 'User profile',
      'firstName': 'First name',
      'lastName': 'Last name',
      'phoneNumber': 'Phone number',
      'roomName': 'Name',
      'roomDescription': 'Description',
      'floor': 'Floor',
      'area': 'Area (m²)',
      'sensorName': 'Name',
      'deviceId': 'Device ID',
      'sensorType': 'Sensor type',
      'status': 'Status',
      'room': 'Room',
      'deviceType': 'Device type',
      'deviceName': 'Device name',
      'airConditioner': 'Air conditioner',
      'heater': 'Heater',
      'humidifier': 'Humidifier',
      'dehumidifier': 'Dehumidifier',
      'operator': 'Operator',
      'value': 'Value',
      'description': 'Description',
      'newThreshold': 'New threshold',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'co2': 'CO₂',
      'pressure': 'Pressure',
      'powerConsumption': 'Power consumption (W)',
      'temperatureMin': 'Min temperature',
      'temperatureMax': 'Max temperature',
      'humidityMin': 'Min humidity',
      'humidityMax': 'Max humidity',
      'autoControlEnabled': 'Auto control enabled',
      'alertType': 'Alert type',
      'message': 'Message',
      'severity': 'Severity',
      'createAlert': 'Create Alert',
      'newAlert': 'New alert',
      'requiredField': 'This field is required',
      'saveFailed': 'Save failed',
      'deleteSuccess': 'Deleted successfully',
      'deleteFailed': 'Delete failed',
      'markRead': 'Mark read',
      'delete': 'Delete',
      'changePassword': 'Change password',
      'oldPassword': 'Old password',
      'newPassword': 'New password',
      'language': 'Language',
      'connectionSettings': 'Connection settings',
      'userSettings': 'User settings',
    },
    'uk': {
      'appTitle': 'Моніторинг клімату',
      'signIn': 'Увійти',
      'register': 'Реєстрація',
      'email': 'Email',
      'password': 'Пароль',
      'createAccount': 'Створити акаунт',
      'sensors': 'Датчики',
      'rooms': 'Кімнати',
      'devices': 'Пристрої',
      'settings': 'Налаштування',
      'profile': 'Профіль',
      'alerts': 'Оповіщення',
      'thresholds': 'Порогові значення',
      'logout': 'Вийти',
      'save': 'Зберегти',
      'saveProfile': 'Зберегти профіль',
      'saveRoom': 'Зберегти кімнату',
      'saveSensor': 'Зберегти датчик',
      'saveDevice': 'Зберегти пристрій',
      'addDevice': 'Додати пристрій',
      'saveConnection': 'Зберегти підключення',
      'testConnection': 'Перевірити підключення',
      'connectionOk': 'Підключення успішне',
      'connectionFailed': 'Помилка підключення',
      'connectionSaved': 'Налаштування підключення збережено',
      'apiBaseUrl': 'URL API',
      'userProfile': 'Профіль користувача',
      'firstName': 'Імʼя',
      'lastName': 'Прізвище',
      'phoneNumber': 'Телефон',
      'roomName': 'Назва',
      'roomDescription': 'Опис',
      'floor': 'Поверх',
      'area': 'Площа (м²)',
      'sensorName': 'Назва',
      'deviceId': 'ID пристрою',
      'sensorType': 'Тип датчика',
      'status': 'Статус',
      'room': 'Кімната',
      'deviceType': 'Тип пристрою',
      'deviceName': 'Назва пристрою',
      'airConditioner': 'Кондиціонер',
      'heater': 'Обігрівач',
      'humidifier': 'Зволожувач',
      'dehumidifier': 'Осушувач',
      'operator': 'Оператор',
      'value': 'Значення',
      'description': 'Опис',
      'newThreshold': 'Новий поріг',
      'temperature': 'Температура',
      'humidity': 'Вологість',
      'co2': 'CO₂',
      'pressure': 'Тиск',
      'powerConsumption': 'Потужність (Вт)',
      'temperatureMin': 'Мін. температура',
      'temperatureMax': 'Макс. температура',
      'humidityMin': 'Мін. вологість',
      'humidityMax': 'Макс. вологість',
      'autoControlEnabled': 'Автоконтроль увімкнено',
      'alertType': 'Тип оповіщення',
      'message': 'Повідомлення',
      'severity': 'Серйозність',
      'createAlert': 'Створити оповіщення',
      'newAlert': 'Нове оповіщення',
      'requiredField': 'Це поле обовʼязкове',
      'saveFailed': 'Помилка збереження',
      'deleteSuccess': 'Видалено успішно',
      'deleteFailed': 'Помилка видалення',
      'markRead': 'Позначити прочитаним',
      'delete': 'Видалити',
      'changePassword': 'Змінити пароль',
      'oldPassword': 'Старий пароль',
      'newPassword': 'Новий пароль',
      'language': 'Мова',
      'connectionSettings': 'Налаштування підключення',
      'userSettings': 'Налаштування користувача',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'uk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

