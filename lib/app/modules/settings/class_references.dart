// This file documents the current active components (unified storage implementation)

// Controllers (ACTIVE)
// - Main controller: SettingsController (core functionality)
// - Wrapper controller: SettingsControllerFixed (compatibility layer with unified storage)
//   ^ This is the one registered in app bindings and used by all views

// Views (ACTIVE)
// - Main Settings view: SettingsViewFixed (uses SettingsControllerFixed)
// - MQTT view: MqttSettingsView (uses SettingsControllerFixed)
// - Web URL view: WebUrlSettingsViewFixed (uses SettingsControllerFixed)
// - AI view: AiSettingsView (uses SettingsControllerFixed)
// - Media view: MediaSettingsView (uses SettingsControllerFixed)
// - Communications view: CommunicationsSettingsView (stateless widget)

// Services (ACTIVE)
// - Storage: StorageService (unified file-based storage with encryption)
// - MQTT: MqttService (consolidated MQTT service)

// Notes:
// - All storage now uses StorageService (no more GetStorage/FlutterSecureStorage)
// - Only sensitive data (PIN, credentials) is encrypted
// - SettingsControllerFixed is the single source of truth for settings
