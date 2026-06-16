import 'package:flutter/material.dart';

import 'screens/pet_screen.dart';

class PawssistantApp extends StatelessWidget {
  const PawssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PetScreen(),
    );
  }
}
