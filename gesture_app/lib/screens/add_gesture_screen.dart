import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/gesture_model.dart';
import '../features/gestures/bloc/gesture_bloc.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AddGestureScreen extends StatefulWidget {
  const AddGestureScreen({super.key});

  @override
  State<AddGestureScreen> createState() => _AddGestureScreenState();
}

class _AddGestureScreenState extends State<AddGestureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Offset?> _points = [];
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey _gestureKey = GlobalKey();

  // Dialog Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String _selectedAction = 'flashlight';
  AppInfo? _selectedApp;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _urlController.dispose();
    super.dispose();
  }
  
  void _onDone() {
      final isGesture = _tabController.index == 0;
      
      // Validation 1: Check if input exists
      if (isGesture && _points.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please draw a gesture first")));
          return;
      }
      if (!isGesture && _codeController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a code first")));
          return;
      }

      // Show Save Dialog
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder( // Use StatefulBuilder to update dialog state
              builder: (context, setStateDialog) {
                  return AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text("Save Gesture", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      // Name Field
                                      TextField(
                                          controller: _nameController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                              labelText: "Gesture Name",
                                              labelStyle: TextStyle(color: Colors.grey),
                                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
                                          ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Action Dropdown
                                      const Text("Action", style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                                      DropdownButton<String>(
                                          value: _selectedAction,
                                          dropdownColor: const Color(0xFF2C2C2C),
                                          isExpanded: true,
                                          underline: Container(height: 1, color: const Color(0xFF6C63FF)),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                          items: const [
                                              DropdownMenuItem(value: 'flashlight', child: Text("Toggle Flashlight")),
                                              DropdownMenuItem(value: 'open_youtube', child: Text("Open YouTube")),
                                              DropdownMenuItem(value: 'open_camera', child: Text("Open Camera")),
                                              DropdownMenuItem(value: 'open_url', child: Text("Open URL")),
                                              DropdownMenuItem(value: 'open_app', child: Text("Launch App")),
                                          ],
                                          onChanged: (val) {
                                              setStateDialog(() => _selectedAction = val!);
                                          },
                                      ),
                                      
                                      // Dynamic Fields
                                      if (_selectedAction == 'open_url')
                                          Padding(
                                              padding: const EdgeInsets.only(top: 16),
                                              child: TextField(
                                                  controller: _urlController,
                                                  style: const TextStyle(color: Colors.white),
                                                  decoration: const InputDecoration(
                                                      labelText: "Enter URL",
                                                      labelStyle: TextStyle(color: Colors.grey),
                                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
                                                  ),
                                              ),
                                          ),
                                          
                                      if (_selectedAction == 'open_app')
                                          Padding(
                                              padding: const EdgeInsets.only(top: 16),
                                              child: InkWell(
                                                  onTap: () async {
                                                      // Close dialog to pick app (or show another dialog on top? Stacked dialogs work)
                                                      // Let's try picking app then updating state
                                                      // Standard picking might need Context from outside? No, context works.
                                                      await _pickApp(context, setStateDialog);
                                                  },
                                                  child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      decoration: const BoxDecoration(
                                                          border: Border(bottom: BorderSide(color: Colors.grey)),
                                                      ),
                                                      child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                              Text(_selectedApp?.name ?? "Select App", style: const TextStyle(color: Colors.white)),
                                                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                                          ],
                                                      ),
                                                  ),
                                              ),
                                          ),
                                  ],
                              ),
                          ),
                      ),
                      actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                              onPressed: () => _save(context),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Save", style: TextStyle(color: Colors.white)),
                          ),
                      ],
                  );
              },
          ),
      );
  }
  
  // Cache for installed apps
  List<AppInfo>? _cachedApps;
  
  Future<void> _pickApp(BuildContext context, StateSetter setStateDialog) async {
       try {
          // Show loading if apps not cached
          if (_cachedApps == null) {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(
                      child: Card(
                          color: Color(0xFF1E1E1E),
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      CircularProgressIndicator(color: Color(0xFF6C63FF)),
                                      SizedBox(height: 16),
                                      Text("Loading apps...", style: TextStyle(color: Colors.white)),
                                  ],
                              ),
                          ),
                      ),
                  ),
              );
              
              _cachedApps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
              
              if (!mounted) return;
              Navigator.pop(context); // Close loading dialog
          }
          
          if (!mounted) return;
          
          // Show app picker with search
          final AppInfo? picked = await showModalBottomSheet<AppInfo>(
              context: context,
              backgroundColor: const Color(0xFF1E1E1E),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => _AppPickerSheet(apps: _cachedApps!),
          );
          
          if (picked != null) {
              setStateDialog(() => _selectedApp = picked);
          }
       } catch (e) {
           print("Error picking app: $e");
       }
  }

  void _save(BuildContext context) {
      if (_nameController.text.isEmpty) return; // Add validation error visual if needed
      
      final isGesture = _tabController.index == 0;
      dynamic data;
      
      if (isGesture) {
          data = _points.map((e) => e == null ? null : {'dx': e.dx, 'dy': e.dy}).toList();
      } else {
          data = _codeController.text;
      }
      
      String? actionData;
      if (_selectedAction == 'open_url') actionData = _urlController.text;
      if (_selectedAction == 'open_app') actionData = _selectedApp?.packageName;

      final gesture = GestureModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          type: isGesture ? 'gesture' : 'code',
          data: data,
          actionId: _selectedAction,
          actionData: actionData,
      );

      context.read<GestureBloc>().add(AddGestureEvent(gesture));
      
      // Close Logic
      Navigator.pop(context); // Close Dialog
      context.pop(); // Close Screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Draw New Gesture", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121212),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: () {
                     setState(() { 
                         _points.clear(); 
                         _codeController.clear();
                     });
                },
            ),
            IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF6C63FF)),
                onPressed: _onDone,
            ),
            const SizedBox(width: 8),
        ],
        bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            tabs: const [
                Tab(icon: Icon(Icons.gesture), text: "Gesture"),
                Tab(icon: Icon(Icons.keyboard), text: "Shortcut"),
            ],
        ),
      ),
      body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
               _buildGestureCanvas(),
               _buildCodeInput(),
          ],
      ),
    );
  }
  
  Widget _buildGestureCanvas() {
    return Container(
      color: Colors.black, // Pure black canvas for drawing
      child: GestureDetector(
         onPanUpdate: (details) {
            setState(() {
               final RenderBox? box = _gestureKey.currentContext?.findRenderObject() as RenderBox?;
               if (box != null) {
                   _points.add(box.globalToLocal(details.globalPosition));
               }
            });
         },
         onPanEnd: (_) => _points.add(null),
         child: RepaintBoundary(
             key: _gestureKey,
             child: CustomPaint(
                painter: _GesturePainter(_points),
                size: Size.infinite,
             ),
         ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Center(
       child: Padding(
         padding: const EdgeInsets.all(32),
         child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, letterSpacing: 4, color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
                hintText: "TYPE CODE", 
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
            ),
         ),
       ),
    );
  }
}

class _GesturePainter extends CustomPainter {
  final List<Offset?> points;
  _GesturePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    // Optional: Draw a subtle grid or guide? No, keep it clean black as per screenshot.
    final paint = Paint()..color = const Color(0xFF6C63FF)..strokeWidth = 5..strokeCap = StrokeCap.round;
    for(int i=0; i<points.length-1; i++) {
       if(points[i]!=null && points[i+1]!=null) canvas.drawLine(points[i]!, points[i+1]!, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// Optimized App Picker Sheet with Search
class _AppPickerSheet extends StatefulWidget {
  final List<AppInfo> apps;
  const _AppPickerSheet({required this.apps});

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<AppInfo> _filteredApps = [];

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.apps;
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.apps;
      } else {
        _filteredApps = widget.apps
            .where((app) => (app.name ?? '').toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Select App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search apps...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // App Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "${_filteredApps.length} apps",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            
            // App List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredApps.length,
                itemBuilder: (ctx, i) {
                  final app = _filteredApps[i];
                  return ListTile(
                    leading: app.icon != null
                        ? Image.memory(app.icon!, width: 40, height: 40)
                        : const Icon(Icons.android, color: Colors.grey, size: 40),
                    title: Text(
                      app.name ?? "Unknown",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      app.packageName ?? "",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(ctx, app),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

