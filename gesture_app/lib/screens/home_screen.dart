import 'package:flutter/material.dart';
import '../../data/models/gesture_model.dart';
import '../features/gestures/bloc/gesture_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Gesture App',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.layers_outlined, color: theme.iconTheme.color), // Layers placeholder
              onPressed: () {}, 
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
              onPressed: () => context.push('/settings'),
            )
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF6C63FF),
            indicatorWeight: 3,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Gestures"),
              Tab(text: "Shortcuts"),
            ],
          ),
        ),
        body: BlocBuilder<GestureBloc, GestureState>(
          builder: (context, state) {
            if (state is GestureLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is GestureError) {
              return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.redAccent)));
            }
            if (state is GestureLoaded) {
              final gestures = state.gestures.where((g) => g.type == 'gesture').toList();
              final codes = state.gestures.where((g) => g.type == 'code').toList();

              return TabBarView(
                children: [
                   _buildList(context, gestures, "gesture"),
                   _buildList(context, codes, "shortcut"),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
             boxShadow: [
               BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
             ]
          ),
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/add'),
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add),
            label: const Text("New Gesture", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<GestureModel> items, String mode) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gesture, size: 80, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              "No ${mode}s yet",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
             const SizedBox(height: 8),
            Text(
              "Tap + to create your first $mode",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCard(context, item);
      },
    );
  }

  Widget _buildCard(BuildContext context, GestureModel gesture) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor, // Or slightly lighter/darker
              borderRadius: BorderRadius.circular(12),
            ),
             child: gesture.type == 'gesture' 
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomPaint(painter: _MiniGesturePainter(gesture.data)),
                  ),
                )
                : Center(child: Text(gesture.data.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gesture.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 4),
                 Text(
                   gesture.actionId,
                   style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                 ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
               // Could show edit/delete bottom sheet here
               context.read<GestureBloc>().add(DeleteGestureEvent(gesture.id));
            },
          ),
        ],
      ),
    );
  }
}

class _MiniGesturePainter extends CustomPainter {
  final dynamic data;
  _MiniGesturePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data is! List) return;
    
    final points = (data as List).map((e) {
      if (e == null) return null;
      final m = Map<String, dynamic>.from(e as Map);
      return Offset(m['dx'] as double, m['dy'] as double);
    }).toList();

    if (points.isEmpty) return;

    // Normalization logic similar to before
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (var p in points) {
      if (p != null) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    
    final width = maxX - minX;
    final height = maxY - minY;
    
    if (width == 0 || height == 0) return;

    final scaleX = size.width / width;
    final scaleY = size.height / height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.8;

    final paint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;
    
    final offsetX = (size.width - width * scale) / 2;
    final offsetY = (size.height - height * scale) / 2;

    for (var p in points) {
      if (p == null) {
        first = true;
        continue;
      }
      final x = (p.dx - minX) * scale + offsetX;
      final y = (p.dy - minY) * scale + offsetY;
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
