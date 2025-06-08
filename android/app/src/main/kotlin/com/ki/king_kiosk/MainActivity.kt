package com.ki.king_kiosk

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity(), MethodCallHandler {
    private val CHANNEL = "com.ki.king_kiosk/kiosk"
    private val TAG = "KioskMainActivity"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName
    private var isKioskModeActive = false
    private var isScreenPinned = false
    private val REQUEST_CODE_ENABLE_ADMIN = 1000
    private val REQUEST_CODE_HOME_SETTINGS = 1001
    private val REQUEST_CODE_BATTERY_OPTIMIZATION = 1002

    companion object {
        private const val PREF_KIOSK_MODE = "kiosk_mode_active"
        private const val PREF_FIRST_LAUNCH = "first_launch_as_home"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize device policy manager
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, KioskDeviceAdminReceiver::class.java)
        
        // Set up method channel for kiosk communication
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
        
        Log.i(TAG, "MainActivity configured with kiosk support")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Keep screen on when in kiosk mode
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Check if launched as home app
        if (isLaunchedAsHomeApp()) {
            Log.i(TAG, "Launched as home app - auto-enabling kiosk mode")
            enableKioskMode()
            
            // Mark first launch to help user understand what happened
            markFirstLaunchAsHome()
        }
        
        // Restore previous kiosk state if needed
        restoreKioskState()
        
        Log.i(TAG, "MainActivity created. Kiosk mode: $isKioskModeActive")
    }

    private fun markFirstLaunchAsHome() {
        val prefs = getSharedPreferences("kiosk_settings", Context.MODE_PRIVATE)
        if (!prefs.getBoolean(PREF_FIRST_LAUNCH, false)) {
            prefs.edit().putBoolean(PREF_FIRST_LAUNCH, true).apply()
            Log.i(TAG, "First launch as home app detected")
        }
    }

    private fun restoreKioskState() {
        val prefs = getSharedPreferences("kiosk_settings", Context.MODE_PRIVATE)
        val wasKioskActive = prefs.getBoolean(PREF_KIOSK_MODE, false)
        if (wasKioskActive && !isKioskModeActive) {
            Log.i(TAG, "Restoring previous kiosk state")
            enableKioskMode()
        }
    }

    private fun saveKioskState() {
        val prefs = getSharedPreferences("kiosk_settings", Context.MODE_PRIVATE)
        prefs.edit().putBoolean(PREF_KIOSK_MODE, isKioskModeActive).apply()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "hasDeviceAdminPermission" -> {
                result.success(devicePolicyManager.isAdminActive(adminComponent))
            }
            "requestDeviceAdminPermission" -> {
                requestDeviceAdminPermission(result)
            }
            "isSetAsHomeApp" -> {
                result.success(isSetAsHomeApp())
            }
            "isDefaultHomeApp" -> {
                result.success(isDefaultHomeApp())
            }
            "setAsHomeLauncher" -> {
                setAsHomeLauncher(result)
            }
            "removeAsHomeLauncher" -> {
                removeAsHomeLauncher(result)
            }
            "enableSystemLockdown" -> {
                enableSystemLockdown(result)
            }
            "disableSystemLockdown" -> {
                disableSystemLockdown(result)
            }
            "hideSystemUI" -> {
                hideSystemUI()
                result.success(true)
            }
            "showSystemUI" -> {
                showSystemUI()
                result.success(true)
            }
            "blockHardwareButtons" -> {
                isKioskModeActive = true
                result.success(true)
            }
            "unblockHardwareButtons" -> {
                isKioskModeActive = false
                result.success(true)
            }
            "isKioskModeActive" -> {
                result.success(isKioskModeActive)
            }
            "enableKioskWithLauncher" -> {
                enableKioskWithLauncher(result)
            }
            "disableKioskAndLauncher" -> {
                disableKioskAndLauncher(result)
            }
            "forceSetAsHomeApp" -> {
                forceSetAsHomeApp(result)
            }
            "clearDefaultLauncher" -> {
                clearDefaultLauncher(result)
            }
            "isTaskLocked" -> {
                result.success(isTaskLocked())
            }
            "enableTaskLock" -> {
                enableTaskLock(result)
            }
            "disableTaskLock" -> {
                disableTaskLock(result)
            }
            "preventAppUninstall" -> {
                preventAppUninstall(result)
            }
            "allowAppUninstall" -> {
                allowAppUninstall(result)
            }
            "rebootDevice" -> {
                rebootDevice(result)
            }
            "lockDevice" -> {
                lockDevice(result)
            }
            "performFullCleanup" -> {
                performFullCleanup(result)
            }
            "forceDisableAllKioskFeatures" -> {
                forceDisableAllKioskFeatures(result)
            }
            "requestIgnoreBatteryOptimization" -> {
                requestIgnoreBatteryOptimization(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isLaunchedAsHomeApp(): Boolean {
        val intent = intent
        return Intent.ACTION_MAIN == intent.action && 
               intent.hasCategory(Intent.CATEGORY_HOME)
    }

    private fun requestDeviceAdminPermission(result: Result?) {
        try {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                "Enable device administrator to use kiosk mode")
            startActivity(intent)
            result?.success(true)
        } catch (e: Exception) {
            result?.success(false)
        }
    }

    private fun isSetAsHomeApp(): Boolean {
        val packageManager = packageManager
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    private fun isDefaultHomeApp(): Boolean {
        val packageManager = packageManager
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        
        for (resolveInfo in resolveInfos) {
            if (resolveInfo.activityInfo.packageName == packageName) {
                return true
            }
        }
        return false
    }

    private fun setAsHomeLauncher(result: Result?) {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            startActivity(intent)
            result?.success(true)
        } catch (e: Exception) {
            result?.success(false)
        }
    }

    private fun removeAsHomeLauncher(result: Result) {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun enableSystemLockdown(result: Result) {
        try {
            isKioskModeActive = true
            hideSystemUI()
            
            // Disable status bar expansion
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
            }
            
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun disableSystemLockdown(result: Result) {
        try {
            isKioskModeActive = false
            showSystemUI()
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
        }
    }

    private fun showSystemUI() {
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
    }

    private fun openLauncherSettings(result: Result) {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun requestIgnoreBatteryOptimization(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun enableKioskMode() {
        isKioskModeActive = true
        hideSystemUI()
        saveKioskState()
        Log.i(TAG, "Kiosk mode enabled")
    }

    // Enhanced kiosk methods
    private fun enableKioskWithLauncher(result: Result) {
        try {
            Log.i(TAG, "Enabling comprehensive kiosk mode with launcher...")
            
            // Step 1: Enable basic kiosk mode
            enableKioskMode()
            
            // Step 2: Request device admin if not already granted
            if (!devicePolicyManager.isAdminActive(adminComponent)) {
                Log.i(TAG, "Requesting device admin permission...")
                try {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                        "Enable device administrator to use kiosk mode")
                    startActivity(intent)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to request device admin: ${e.message}")
                }
            }
            
            // Step 3: Set as home launcher
            try {
                val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                startActivity(intent)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to open home settings: ${e.message}")
            }
            
            // Step 4: Enable task lock if supported
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    startLockTask()
                    isScreenPinned = true
                    Log.i(TAG, "✅ Task lock enabled (screen pinning)")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to enable task lock: ${e.message}")
                }
            }
            
            result.success(true)
            Log.i(TAG, "✅ Comprehensive kiosk mode enabled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to enable comprehensive kiosk mode", e)
            result.success(false)
        }
    }

    private fun disableKioskAndLauncher(result: Result) {
        try {
            Log.i(TAG, "Disabling comprehensive kiosk mode...")
            
            // Step 1: Disable task lock
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && isScreenPinned) {
                try {
                    stopLockTask()
                    isScreenPinned = false
                    Log.i(TAG, "✅ Task lock disabled")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to disable task lock: ${e.message}")
                }
            }
            
            // Step 2: Show system UI
            showSystemUI()
            
            // Step 3: Clear launcher status
            try {
                val packageManager = packageManager
                packageManager.clearPackagePreferredActivities(packageName)
                Log.i(TAG, "✅ Cleared default launcher preference")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clear default launcher: ${e.message}")
            }
            
            // Step 4: Disable kiosk mode
            isKioskModeActive = false
            saveKioskState()
            
            result.success(true)
            Log.i(TAG, "✅ Comprehensive kiosk mode disabled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to disable comprehensive kiosk mode", e)
            result.success(false)
        }
    }

    private fun forceSetAsHomeApp(result: Result) {
        try {
            // Clear current default launcher first
            clearDefaultLauncher(null)
            
            // Then request to set as home
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            
            result.success(true)
            Log.i(TAG, "✅ Forced home app selection")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to force set as home app", e)
            result.success(false)
        }
    }

    private fun clearDefaultLauncher(result: Result?) {
        try {
            val packageManager = packageManager
            packageManager.clearPackagePreferredActivities(packageName)
            
            result?.success(true)
            Log.i(TAG, "✅ Cleared default launcher preference")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to clear default launcher", e)
            result?.success(false)
        }
    }

    private fun isTaskLocked(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            isScreenPinned
        } else {
            false
        }
    }

    private fun enableTaskLock(result: Result?) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                startLockTask()
                isScreenPinned = true
                result?.success(true)
                Log.i(TAG, "✅ Task lock enabled (screen pinning)")
            } else {
                result?.success(false)
                Log.w(TAG, "❌ Task lock not supported on this Android version")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to enable task lock", e)
            result?.success(false)
        }
    }

    private fun disableTaskLock(result: Result?) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && isScreenPinned) {
                stopLockTask()
                isScreenPinned = false
                result?.success(true)
                Log.i(TAG, "✅ Task lock disabled")
            } else {
                result?.success(false)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to disable task lock", e)
            result?.success(false)
        }
    }

    private fun preventAppUninstall(result: Result) {
        try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    devicePolicyManager.setUninstallBlocked(adminComponent, packageName, true)
                    result.success(true)
                    Log.i(TAG, "✅ App uninstall blocked")
                } else {
                    result.success(false)
                    Log.w(TAG, "❌ App uninstall blocking not supported on this Android version")
                }
            } else {
                result.success(false)
                Log.w(TAG, "❌ Device admin required to block app uninstall")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to prevent app uninstall", e)
            result.success(false)
        }
    }

    private fun allowAppUninstall(result: Result) {
        try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    devicePolicyManager.setUninstallBlocked(adminComponent, packageName, false)
                    result.success(true)
                    Log.i(TAG, "✅ App uninstall allowed")
                } else {
                    result.success(false)
                }
            } else {
                result.success(false)
                Log.w(TAG, "❌ Device admin required to manage app uninstall")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to allow app uninstall", e)
            result.success(false)
        }
    }

    private fun rebootDevice(result: Result) {
        try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    devicePolicyManager.reboot(adminComponent)
                    result.success(true)
                    Log.i(TAG, "✅ Device reboot initiated")
                } else {
                    result.success(false)
                    Log.w(TAG, "❌ Device reboot not supported on this Android version")
                }
            } else {
                result.success(false)
                Log.w(TAG, "❌ Device admin required to reboot device")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to reboot device", e)
            result.success(false)
        }
    }

    private fun lockDevice(result: Result) {
        try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.lockNow()
                result.success(true)
                Log.i(TAG, "✅ Device locked")
            } else {
                result.success(false)
                Log.w(TAG, "❌ Device admin required to lock device")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to lock device", e)
            result.success(false)
        }
    }

    private fun performFullCleanup(result: Result) {
        try {
            Log.i(TAG, "🔒 Performing full kiosk cleanup...")
            
            // Step 1: Disable kiosk mode state
            isKioskModeActive = false
            isScreenPinned = false
            saveKioskState()
            
            // Step 2: Show system UI
            showSystemUI()
            
            // Step 3: Disable task lock if active
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    stopLockTask()
                } catch (e: Exception) {
                    Log.w(TAG, "Task lock was not active or failed to stop: ${e.message}")
                }
            }
            
            // Step 4: Clear any window flags that might interfere
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            
            // Step 5: Allow app uninstall if device admin is active
            try {
                if (devicePolicyManager.isAdminActive(adminComponent)) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        devicePolicyManager.setUninstallBlocked(adminComponent, packageName, false)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to allow app uninstall: ${e.message}")
            }
            
            // Step 6: Clear launcher preferences
            try {
                val packageManager = packageManager
                packageManager.clearPackagePreferredActivities(packageName)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clear launcher preferences: ${e.message}")
            }
            
            result.success(true)
            Log.i(TAG, "✅ Full kiosk cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to perform full cleanup", e)
            result.success(false)
        }
    }

    private fun forceDisableAllKioskFeatures(result: Result) {
        try {
            Log.i(TAG, "🔒 Force disabling ALL kiosk features...")
            
            // Reset all internal state
            isKioskModeActive = false
            isScreenPinned = false
            
            // Clear shared preferences
            val prefs = getSharedPreferences("kiosk_settings", Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            
            // Force show system UI with all flags cleared
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_VISIBLE or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
            
            // Clear all window flags
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            window.clearFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
            
            // Force stop task lock regardless of state
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                try {
                    stopLockTask()
                } catch (e: Exception) {
                    // Ignore if not in task lock
                }
            }
            
            // Clear package preferences multiple times to ensure it takes effect
            try {
                val packageManager = packageManager
                packageManager.clearPackagePreferredActivities(packageName)
                packageManager.clearPackagePreferredActivities(packageName)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clear package preferences: ${e.message}")
            }
            
            // Remove device admin if possible (this will require user interaction)
            try {
                if (devicePolicyManager.isAdminActive(adminComponent)) {
                    // Allow app uninstall first
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        devicePolicyManager.setUninstallBlocked(adminComponent, packageName, false)
                    }
                    
                    // Note: We cannot programmatically remove device admin, user must do it manually
                    Log.i(TAG, "Device admin is still active - user must manually remove it from Settings > Security > Device Administrators")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to manage device admin: ${e.message}")
            }
            
            result.success(true)
            Log.i(TAG, "✅ Force disable of all kiosk features completed")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to force disable kiosk features", e)
            result.success(false)
        }
    }

    // Override hardware button behavior in kiosk mode
    override fun onBackPressed() {
        if (isKioskModeActive) {
            Log.d(TAG, "🔒 Back button blocked in kiosk mode")
            return
        }
        super.onBackPressed()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isKioskModeActive) {
            return when (keyCode) {
                KeyEvent.KEYCODE_HOME,
                KeyEvent.KEYCODE_RECENT_APPS,
                KeyEvent.KEYCODE_APP_SWITCH,
                KeyEvent.KEYCODE_MENU,
                KeyEvent.KEYCODE_SEARCH,
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    Log.d(TAG, "🔒 Hardware key blocked in kiosk mode: $keyCode")
                    true // Block the key
                }
                else -> super.onKeyDown(keyCode, event)
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onUserLeaveHint() {
        if (isKioskModeActive) {
            Log.d(TAG, "🔒 User tried to leave app - bringing back to foreground")
            // Bring app back to foreground if user tries to leave
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
        }
        super.onUserLeaveHint()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (isKioskModeActive && hasFocus) {
            // Re-hide system UI when focus returns to ensure immersion
            hideSystemUI()
        }
        if (isKioskModeActive && !hasFocus) {
            Log.d(TAG, "🔒 Window lost focus in kiosk mode - attempting to regain focus")
            // Try to bring app back to focus
            window.decorView.postDelayed({
                if (isKioskModeActive) {
                    val intent = Intent(this, MainActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    startActivity(intent)
                }
            }, 100)
        }
    }

    override fun onPause() {
        super.onPause()
        if (isKioskModeActive) {
            Log.d(TAG, "🔒 App paused in kiosk mode - will attempt to resume")
        }
    }

    override fun onResume() {
        super.onResume()
        if (isKioskModeActive) {
            Log.d(TAG, "🔒 App resumed in kiosk mode")
            hideSystemUI()
        }
    }

    override fun onStop() {
        super.onStop()
        if (isKioskModeActive) {
            Log.d(TAG, "🔒 App stopped in kiosk mode - bringing back to foreground")
            // Immediately bring back to foreground
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_CODE_ENABLE_ADMIN -> {
                if (resultCode == Activity.RESULT_OK) {
                    Log.i(TAG, "✅ Device admin permission granted")
                } else {
                    Log.w(TAG, "❌ Device admin permission denied")
                }
            }
            REQUEST_CODE_HOME_SETTINGS -> {
                Log.i(TAG, "Returned from home settings")
                // Check if we're now the default launcher
                val isNowHome = isDefaultHomeApp()
                Log.i(TAG, "Is now default home app: $isNowHome")
            }
            REQUEST_CODE_BATTERY_OPTIMIZATION -> {
                Log.i(TAG, "Returned from battery optimization settings")
            }
        }
    }
}
