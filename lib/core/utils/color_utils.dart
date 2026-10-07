import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ColorUtils {
  static String getRandomColorHex() {
    final random = Random();
    final color = AppColors.sessionColors[random.nextInt(AppColors.sessionColors.length)];
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
