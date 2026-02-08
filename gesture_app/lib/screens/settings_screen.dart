import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/bubble_customizer.dart';
import '../data/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _opacity = 1.0;
  String _size = 'medium';
  String _color = 'black';
  String _icon = 'pen';
  

  // New Settings with Defaults
  bool _isDarkMode = true;
  bool _hapticEnabled = true;
  double _sensitivity = 0.80;
  int _trailColor = 0xFF6C63FF;
  bool _lockPosition = false;
  bool _shakeToWake = false;

  final ApiService _apiService = ApiService();
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() {
      // Just reading, UI will rebuild if we setState, but this usually runs before first build frame, 
      // however Hive operations are sync for read if box is open.
      _isDarkMode = _settingsBox.get('is_dark_mode', defaultValue: true);
      _hapticEnabled = _settingsBox.get('haptic', defaultValue: true);
      _sensitivity = _settingsBox.get('sensitivity', defaultValue: 0.80);
      _trailColor = _settingsBox.get('trail_color', defaultValue: 0xFF6C63FF);
      _lockPosition = _settingsBox.get('lock_position', defaultValue: false);
      _shakeToWake = _settingsBox.get('shake_to_wake', defaultValue: false);
  }

  void _updateTheme(bool val) {
    setState(() => _isDarkMode = val);
    _settingsBox.put('is_dark_mode', val);
  }

  void _updateOpacity(double val) {
    setState(() => _opacity = val);
    BubbleCustomizer.updateBubbleOpacity(val);
  }

  void _updateSize(String val) {
    setState(() => _size = val);
    BubbleCustomizer.updateBubbleSize(val);
  }
  
  void _updateColor(String type) {
    setState(() => _color = type);
    String hex = "#424242"; 
    if (type == 'glass') hex = "#88FFFFFF";
    if (type == 'neon') hex = "#6C63FF";
    BubbleCustomizer.updateBubbleColor(hex);
  }

  void _updateIcon(String icon) {
     setState(() => _icon = icon);
     BubbleCustomizer.updateBubbleIcon(icon);
  }
  
  void _updateHaptic(bool val) {
      setState(() => _hapticEnabled = val);
      _settingsBox.put('haptic', val);
  }

  void _updateSensitivity(double val) {
      setState(() => _sensitivity = val);
      _settingsBox.put('sensitivity', val);
  }
  
  void _updateTrailColor(int val) {
      setState(() => _trailColor = val);
      _settingsBox.put('trail_color', val);
  }
  
  void _updateLockPosition(bool val) {
      setState(() => _lockPosition = val);
      _settingsBox.put('lock_position', val);
      BubbleCustomizer.updateBubbleLock(val);
  }

  void _updateShakeToWake(bool val) {
      setState(() => _shakeToWake = val);
      _settingsBox.put('shake_to_wake', val);
      BubbleCustomizer.updateShakeToWake(val);
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          _buildControlCard(
             title: "Appearance",
             subtitle: "App Theme",
             child: SwitchListTile(
                 activeColor: const Color(0xFF6C63FF),
                 contentPadding: EdgeInsets.zero,
                 title: Text(_isDarkMode ? "Dark Mode" : "Light Mode", style: TextStyle(color: textColor)),
                 secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: textColor),
                 value: _isDarkMode,
                 onChanged: _updateTheme,
             ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader("Bubble Appearance"),
          
          _buildControlCard(
            title: "Opacity",
            subtitle: "Adjust bubble transparency",
            child: Slider(
              value: _opacity,
              min: 0.1,
              max: 1.0,
              activeColor: const Color(0xFF6C63FF),
              onChanged: _updateOpacity,
            ),
          ),

          _buildControlCard(
            title: "Size", 
            subtitle: "Select bubble radius",
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                  _buildSelectChip("Small", 'small', _size == 'small', (v) => _updateSize('small')),
                  _buildSelectChip("Medium", 'medium', _size == 'medium', (v) => _updateSize('medium')),
                  _buildSelectChip("Large", 'large', _size == 'large', (v) => _updateSize('large')),
               ],
            )
          ),

          _buildControlCard(
             title: "Style",
             subtitle: "Choose visual theme",
             child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildColorCircle("OLED", Colors.grey[900]!, _color == 'black', () => _updateColor('black')),
                   _buildColorCircle("Glass", Colors.white38, _color == 'glass', () => _updateColor('glass')),
                   _buildColorCircle("Neon", const Color(0xFF6C63FF), _color == 'neon', () => _updateColor('neon')),
                ],
             ),
          ),
          
          _buildControlCard(
             title: "Icon",
             subtitle: "Center symbol",
             child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildIconOption(Icons.edit, 'pen', _icon == 'pen', () => _updateIcon('pen')),
                   _buildIconOption(Icons.flash_on, 'bolt', _icon == 'bolt', () => _updateIcon('bolt')),
                   _buildIconOption(Icons.circle, 'dot', _icon == 'dot', () => _updateIcon('dot')),
                ],
             ),
          ),
          
          _buildControlCard(
             title: "Lock Position",
             subtitle: "Prevent dragging the bubble",
             child: SwitchListTile(
                 activeColor: const Color(0xFF6C63FF),
                 contentPadding: EdgeInsets.zero,
                 title: Text("Lock Movement", style: TextStyle(color: textColor)),
                 value: _lockPosition,
                 onChanged: _updateLockPosition,
             ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader("Interaction & Engine"),

          _buildControlCard(
             title: "Haptic Feedback",
             subtitle: "Vibrate on match or error",
             child: SwitchListTile(
                 activeColor: const Color(0xFF6C63FF),
                 contentPadding: EdgeInsets.zero,
                 title: Text("Vibration", style: TextStyle(color: textColor)),
                 value: _hapticEnabled,
                 onChanged: _updateHaptic,
             ),
          ),
          
          _buildControlCard(
             title: "Shake to Wake",
             subtitle: "Open canvas by shaking device",
             child: SwitchListTile(
                 activeColor: const Color(0xFF6C63FF),
                 contentPadding: EdgeInsets.zero,
                 title: Text("Shake Detection", style: TextStyle(color: textColor)),
                 value: _shakeToWake,
                 onChanged: _updateShakeToWake,
             ),
          ),
          
          _buildControlCard(
             title: "Strictness",
             subtitle: "Threshold: ${(_sensitivity * 100).toInt()}% match required",
             child: Slider(
                value: _sensitivity,
                min: 0.60,
                max: 0.95,
                divisions: 7,
                activeColor: const Color(0xFF6C63FF),
                onChanged: _updateSensitivity,
             ),
          ),

          _buildControlCard(
             title: "Trail Color",
             subtitle: "Drawing path color",
             child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                     _buildColorCircle("Purple", const Color(0xFF6C63FF), _trailColor == 0xFF6C63FF, () => _updateTrailColor(0xFF6C63FF)),
                     _buildColorCircle("Cyan", Colors.cyanAccent, _trailColor == Colors.cyanAccent.value, () => _updateTrailColor(Colors.cyanAccent.value)),
                     _buildColorCircle("Green", Colors.greenAccent, _trailColor == Colors.greenAccent.value, () => _updateTrailColor(Colors.greenAccent.value)),
                 ],
             ),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
             width: double.infinity,
             child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.red.withOpacity(0.1),
                   foregroundColor: Colors.red,
                   padding: const EdgeInsets.all(16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
             ),
          ),
          const SizedBox(height: 20),
          Center(child: Text("Version 1.0.0", style: TextStyle(color: subTextColor))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
     return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
     );
  }
  
  Widget _buildControlCard({required String title, required String subtitle, required Widget child}) {
     final theme = Theme.of(context);
     return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: theme.cardColor,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                 ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 16),
              child,
           ],
        ),
     );
  }
  
  Widget _buildSelectChip(String label, String value, bool isSelected, Function(bool) onSelected) {
     final theme = Theme.of(context);
     return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: const Color(0xFF6C63FF),
        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
        labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6)),
        side: BorderSide.none,
     );
  }
  
  Widget _buildColorCircle(String label, Color color, bool isSelected, VoidCallback onTap) {
      final theme = Theme.of(context);
      return GestureDetector(
         onTap: onTap,
         child: Column(
            children: [
               Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                     color: color,
                     shape: BoxShape.circle,
                     border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2) : Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
               ),
               const SizedBox(height: 8),
               Text(label, style: TextStyle(color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
            ],
         ),
      );
  }
  
  Widget _buildIconOption(IconData icon, String value, bool isSelected, VoidCallback onTap) {
      final theme = Theme.of(context);
      return GestureDetector(
         onTap: onTap,
         child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: isSelected ? const Color(0xFF6C63FF) : theme.colorScheme.onSurface.withOpacity(0.05),
               borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : theme.colorScheme.onSurface),
         )
      );
  }
}
