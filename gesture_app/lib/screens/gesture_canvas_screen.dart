import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/gestures/bloc/gesture_bloc.dart';
import 'package:torch_light/torch_light.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as ul; 
import '../data/models/gesture_model.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../data/services/api_service.dart';

class GestureCanvasScreen extends StatefulWidget {
  const GestureCanvasScreen({super.key});

  @override
  State<GestureCanvasScreen> createState() => _GestureCanvasScreenState();
}

class _GestureCanvasScreenState extends State<GestureCanvasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Offset?> _points = [];
  final TextEditingController _codeController = TextEditingController();
  Timer? _debounceTimer;

  // Track if we are processing to prevent double triggers
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _processInput() async {
     if (_isProcessing) return;
     _isProcessing = true;
     
     final repository = context.read<GestureBloc>().repository;
     final settings = Hive.box('settings');
     final sensitivity = settings.get('sensitivity', defaultValue: 0.80);
     final haptic = settings.get('haptic', defaultValue: true);
     
     GestureModel? match;

     if (_tabController.index == 0) {
        final cleanPoints = _points.whereType<Offset>().toList();
        // Pass sensitivity explicitly if repository supports it, 
        // OR simply update repository implementation to read settings?
        // Updating repository is cleaner (separation of concerns), but passing is functional.
        // Repository currently doesn't accept threshold. 
        // I will UPDATE repository to accept an optional threshold.
        match = repository.findMatch(cleanPoints, threshold: sensitivity);
     } else {
        match = repository.findCodeMatch(_codeController.text);
     }

     if (match != null) {
        if (mounted && haptic) {
           HapticFeedback.mediumImpact();
        }
        
        // Log Usage (Fire & Forget)
        ApiService().logUsage(match.name, match.actionId);

        await _executeAction(match.actionId, match.actionData);
        if (mounted) {
            SystemNavigator.pop();
        }
     } else {
        if (mounted) {
           if (haptic) HapticFeedback.heavyImpact();
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No match found")));
        }
     }
     _isProcessing = false;
  }
  
  Future<void> _executeAction(String actionId, String? data) async {
       try {
           if (actionId == 'flashlight') {
               try { await TorchLight.enableTorch(); } catch (_) { await TorchLight.disableTorch(); }
           } else if (actionId == 'open_camera') {
                await LaunchApp.openApp(androidPackageName: 'com.android.camera');
           } else if (actionId == 'open_youtube') {
                await LaunchApp.openApp(androidPackageName: 'com.google.android.youtube');
           } else if (actionId == 'open_url' && data != null) {
                final uri = Uri.parse(data.startsWith('http') ? data : 'https://$data');
                if (await ul.canLaunchUrl(uri)) {
                    await ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
                }
           } else if (actionId == 'open_app' && data != null) {
                await LaunchApp.openApp(androidPackageName: data);
           }
       } catch (e) {
           print("Execution error: $e");
       }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    setState(() {
      final RenderBox object = context.findRenderObject() as RenderBox;
      final localPosition = object.globalToLocal(details.globalPosition);
      _points.add(localPosition);
    });
  }
  
  void _handlePanEnd(DragEndDetails details) {
      _points.add(null);
      // Wait 1s then execute
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
           if (mounted && _points.isNotEmpty) {
               _processInput();
           }
      });
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _debounceTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Backdrop blur for 'frosted glass' effect, no simple opacity
    final trailColor = Hive.box('settings').get('trail_color', defaultValue: 0xFF6C63FF);
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
            // Background Blur
            Positioned.fill(
                child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                ),
            ),
            
            // Canvas (Full Screen)
            if (_tabController.index == 0)
                GestureDetector(
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    child: CustomPaint(
                        painter: _GesturePainter(_points, Color(trailColor)),
                        size: Size.infinite,
                    ),
                ),
            
            // Content Layout
            SafeArea(
                child: Column(
                    children: [
                        // Top Header (Clean Options)
                        Container(
                            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                    color: const Color(0xFF6C63FF),
                                    borderRadius: BorderRadius.circular(25),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.gesture, size: 18), SizedBox(width: 8), Text("Gesture")])),
                                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.keyboard, size: 18), SizedBox(width: 8), Text("Code")])),
                                ],
                                onTap: (index) {
                                    setState(() {});
                                },
                            ),
                        ),
                        
                        // Main Content Area
                        Expanded(
                             child: _tabController.index == 1 ? _buildCodeInput() : const SizedBox.shrink(),
                        ),
                        
                        // Bottom Controls
                        Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white70, size: 32),
                                        onPressed: () => SystemNavigator.pop(),
                                    ),
                                    const SizedBox(width: 20),
                                    if (_tabController.index == 0)
                                        IconButton(
                                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 32),
                                            onPressed: _clearCanvas,
                                        ),
                                    if (_tabController.index == 1)
                                        IconButton(
                                            icon: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                                                child: const Icon(Icons.check, color: Colors.white, size: 24),
                                            ),
                                            onPressed: _processInput,
                                        ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: TextField(
          controller: _codeController,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.bold),
          cursorColor: const Color(0xFF6C63FF),
          decoration: const InputDecoration(
            hintText: "TYPE CODE",
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _processInput(),
        ),
      ),
    );
  }
}

class _GesturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  _GesturePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Smoother, cleaner stroke
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 12.0 // Thicker, confident stroke
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;
    
    for (int i = 0; i < points.length; i++) {
        if (points[i] == null) {
            first = true;
            continue;
        }
        if (first) {
            path.moveTo(points[i]!.dx, points[i]!.dy);
            first = false;
        } else {
            path.lineTo(points[i]!.dx, points[i]!.dy);
        }
    }
    
    // No blur, just clean render
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
