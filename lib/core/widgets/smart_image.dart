import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SmartImage extends StatelessWidget {
  final String pathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.pathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackWidget =
        errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.mintBg,
          child: const Center(
            child: Icon(Icons.eco, size: 44, color: AppColors.primaryGreen),
          ),
        );

    final cleanString = pathOrUrl.trim();

    if (cleanString.isEmpty) {
      return fallbackWidget;
    }

    if (cleanString.startsWith('http://') ||
        cleanString.startsWith('https://')) {
      return Image.network(
        cleanString,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallbackWidget,
      );
    }

    try {
      final file = File(cleanString);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallbackWidget,
        );
      }
    } catch (_) {}

    return Image.network(
      cleanString,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallbackWidget,
    );
  }
}
