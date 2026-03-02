class DemoFlags {
  DemoFlags._();

  // Presentation mode toggle.
  // Override with: --dart-define=PRESENTATION_MODE=false
  static const bool presentationMode = bool.fromEnvironment(
    'PRESENTATION_MODE',
    defaultValue: true,
  );
}
