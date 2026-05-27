// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class OnboardingScreen extends StatelessWidget {
//   const OnboardingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const pink = Color(0xFFFF4F7B);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 28),
//           child: Column(
//             children: [
//               const Spacer(),
//               const Icon(Icons.favorite, color: pink, size: 72),
//               const SizedBox(height: 34),
//               const Text(
//                 'Veloura',
//                 style: TextStyle(
//                   color: Color(0xFF111111),
//                   fontSize: 42,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Знакомства, которые начинаются красиво',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Color(0xFF8A8A8A),
//                   fontSize: 16,
//                   height: 1.4,
//                 ),
//               ),
//               const Spacer(),
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: () => context.go('/sign-up'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: pink,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     'Создать аккаунт',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               GestureDetector(
//                 onTap: () => context.go('/sign-in'),
//                 child: const Text(
//                   'У меня уже есть аккаунт',
//                   style: TextStyle(
//                     color: pink,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 34),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }