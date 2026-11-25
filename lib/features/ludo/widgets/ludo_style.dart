import 'package:flutter/material.dart';

import '../engine/ludo_engine.dart';

const Color ludoInk = Color(0xFF100D13);
const Color ludoPanel = Color(0xFF211820);
const Color ludoGold = Color(0xFFFFC95C);
const Color ludoCream = Color(0xFFFFF1D2);
const Color ludoWood = Color(0xFF542D1B);
const Map<LudoColor, Color> ludoPlayerColors = {
  LudoColor.red: Color(0xFFE94345),
  LudoColor.green: Color(0xFF26B85D),
  LudoColor.yellow: Color(0xFFF1B52F),
  LudoColor.blue: Color(0xFF2680F5),
};
const Map<LudoColor, String> ludoPlayerNames = {
  LudoColor.red: 'سارة',
  LudoColor.green: 'محمد',
  LudoColor.yellow: 'علي',
  LudoColor.blue: 'أحمد',
};
const Map<LudoColor, String> ludoPlayerAvatars = {
  LudoColor.red: 'assets/images/avatars/sara.png',
  LudoColor.green: 'assets/images/avatars/mohammed.png',
  LudoColor.yellow: 'assets/images/avatars/ali.png',
  LudoColor.blue: 'assets/images/avatars/ahmed.png',
};
