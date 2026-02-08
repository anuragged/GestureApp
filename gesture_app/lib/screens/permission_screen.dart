import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permissions.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onDone;

  const PermissionScreen({super.key, required this.onDone});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _overlayGranted = false;
  bool _batteryOptimizationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    final perms = await PermissionHelper.checkPermissions();
    
    final notifGranted = status.isGranted || (perms['notification'] ?? false);

    if (mounted) {
      setState(() {
        _notificationGranted = notifGranted;
        _overlayGranted = perms['overlay'] ?? false;
        _batteryOptimizationGranted = perms['battery_optimization'] ?? false;
      });
    }
  }
  
  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
       _checkPermissions();
    } else if (status.isPermanentlyDenied) {
       PermissionHelper.openNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _notificationGranted && _overlayGranted && _batteryOptimizationGranted;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enable Gestures',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant permissions to activate the floating gesture bubble.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      title: 'Notifications',
                      description: 'Required to keep the service running in the background.',
                      isGranted: _notificationGranted,
                      onTap: _notificationGranted ? () {} : _requestNotification,
                      icon: Icons.notifications,
                    ),
                    _buildPermissionCard(
                      title: 'Display Over Other Apps',
                      description: 'Allows the bubble to float above other applications.',
                      isGranted: _overlayGranted,
                      onTap: _overlayGranted ? () {} : () {
                        PermissionHelper.requestOverlay();
                      },
                      icon: Icons.layers,
                    ),
                    _buildPermissionCard(
                      title: 'Keep Running',
                      description: 'Prevent the system from killing the background service.',
                      isGranted: _batteryOptimizationGranted,
                      onTap: _batteryOptimizationGranted ? () {} : () {
                        PermissionHelper.requestBatteryOptimization();
                      },
                      icon: Icons.battery_alert,
                    ),
                  ],
                ),
              ),
              if (allGranted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGranted ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGranted ? Icons.check : icon,
                    color: isGranted ? Colors.green : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                if (isGranted)
                   const Icon(Icons.check_circle, color: Colors.green)
                else
                   const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
