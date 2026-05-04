import 'package:flutter/material.dart';

import 'screens/input_screen.dart';
import 'theme.dart';

class RideCompareApp extends StatelessWidget {
  const RideCompareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideCompare',
      theme: rideCompareTheme,
      home: const InputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
