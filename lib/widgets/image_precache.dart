import 'package:flutter/material.dart';

class ImagePreloader {
  /// Add every onboarding / hero image here
  static const List<String> _onboardingImages = [
    'assets/onbo_grid.png',
    'assets/mainmarketonbo.png',
    'assets/eggsonbo.png',
  ];

  /// Preload all images into memory
  static Future<void> preloadOnboardingImages(BuildContext context) async {
    final futures = _onboardingImages.map(
      (imagePath) => precacheImage(AssetImage(imagePath), context),
    );

    await Future.wait(
      futures.map((future) => future.catchError((_) {})),
      eagerError: false,
    );
  }
}
