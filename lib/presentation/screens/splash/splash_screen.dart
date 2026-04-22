import '../../../core/theme/theme_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// 
// class SplashScreen extends StatefulWidget {
//   SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;
//   late Animation<double> _fade;
//   late Animation<double> _scale;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 1200),
//     );
//     _fade = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
//     );
//     _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _ctrl,
//         curve: Curves.easeOutBack,
//       ),
//     );
//     _ctrl.forward();
//     Future.delayed(Duration(seconds: 3), () {
//       if (mounted) context.go('/login');
//     });
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: context.colors.splashGradient,
//         ),
//         child: Center(
//           child: FadeTransition(
//             opacity: _fade,
//             child: ScaleTransition(
//               scale: _scale,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(28),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.3),
//                         width: 1.5,
//                       ),
//                     ),
//                     child: Icon(
//                       Icons.school_rounded,
//                       color: Colors.white,
//                       size: 55,
//                     ),
//                   ),
//                   SizedBox(height: 28),
//                   // Yogya wordmark
//                   Text(
//                     'Yogya',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 48,
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'THE DIGITAL SANCTUARY',
//                     style: TextStyle(
//                       color: Colors.white60,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w300,
//                       letterSpacing: 4,
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     'COMMITTED EXCELLENCE IN EXAM PREP',
//                     style: TextStyle(
//                       color: Colors.white38,
//                       fontSize: 10,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                   SizedBox(height: 80),
//                   // Loading dots
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(3, (i) {
//                       return Container(
//                         margin: EdgeInsets.symmetric(
//                           horizontal: 4,
//                         ),
//                         width: i == 1 ? 20 : 8,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: i == 1
//                               ? Colors.white
//                               : Colors.white38,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       );
//                     }),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    // Display splash for minimum 2.5 seconds
    // Then navigate based on auth state
    Future.delayed(Duration(milliseconds: 2500), () {
      if (!mounted) return;

      // Navigation will be handled by router's redirect logic
      // Or fallback to login if router doesn't handle it
      context.go('/login');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.splashGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),
                  SizedBox(height: 28),

                  // Wordmark
                  Text(
                    'Yogya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'THE DIGITAL SANCTUARY',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'COMMITTED EXCELLENCE IN EXAM PREP',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 80),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: i == 1 ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == 1 ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
