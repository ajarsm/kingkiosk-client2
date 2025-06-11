// Web-specific secure storage configuration
// This file provides additional configuration for flutter_secure_storage on web

window.flutterSecureStorageConfig = {
  // Use sessionStorage for temporary secrets (cleared on tab close)
  useSessionStorage: false,
  
  // Use localStorage for persistent storage (survives browser restart)
  useLocalStorage: true,
  
  // Enable encryption for stored values (when supported)
  encryptValues: true,
  
  // Storage key prefix to avoid conflicts
  keyPrefix: 'kingkiosk_secure_',
  
  // Maximum storage size (in bytes)
  maxStorageSize: 5 * 1024 * 1024, // 5MB
  
  // Enable debug logging
  debugMode: false
};

// Check for storage API support
if ('storage' in navigator && 'estimate' in navigator.storage) {
  navigator.storage.estimate().then(estimate => {
    console.log('Storage quota:', estimate.quota);
    console.log('Storage usage:', estimate.usage);
  });
}

// Request persistent storage if available
if ('storage' in navigator && 'persist' in navigator.storage) {
  navigator.storage.persist().then(persistent => {
    console.log('Persistent storage:', persistent);
  });
}
