import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _isLastPage = index == 2);
            },
            children: const [
              _Slide(
                title: "Welcome to Gesture App",
                description: "Automate your tasks by simply drawing gestures on your screen.",
                icon: Icons.touch_app,
              ),
              _Slide(
                title: "Gestures & Codes",
                description: "Draw custom shapes or enter secret codes to trigger actions like Flashlight or Camera.",
                icon: Icons.gesture,
              ),
              _Slide(
                title: "Permissions Needed",
                description: "We need a few permissions to float above other apps and detect your magic touch.",
                icon: Icons.security,
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: const WormEffect(
                  activeDotColor: Colors.deepPurple,
                  dotColor: Colors.grey,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _isLastPage
                ? ElevatedButton(
                    onPressed: () => context.go('/permissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _controller.jumpToPage(2),
                        child: const Text("SKIP"),
                      ),
                      IconButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
          )
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _Slide({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.deepPurple),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
