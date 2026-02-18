import 'package:flutter/material.dart';

class OnboardingAssetImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final Color placeholderColor;

  const OnboardingAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.placeholderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : size.width) *
            dpr;
        final height = (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : size.height) *
            dpr;

        final imageProvider = ResizeImage.resizeIfNeeded(
          width.round(),
          height.round(),
          AssetImage(assetPath),
        );

        return ColoredBox(
          color: placeholderColor,
          child: Image(
            image: imageProvider,
            fit: fit,
            filterQuality: FilterQuality.low,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              final isReady = wasSynchronouslyLoaded || frame != null;
              return AnimatedOpacity(
                opacity: isReady ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
