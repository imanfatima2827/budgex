import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Montserrat';
  static const String titleFontFamily = 'BebasNeue';

  // Single source of truth for the complete app color system.
  static const Color primary = Color(0xFF005DFF);
  static const Color primaryDark = Color(0xFF0047C7);
  static const Color teal = Color(0xFF00A6FF);
  static const Color accent = Color(0xFF14B8A6);
  static const Color background = Color(0xFFF5F6FA);
  static const Color bg = background;
  static const Color card = Colors.white;
  static const Color softSurface = Color.fromARGB(255, 238, 238, 240);
  static const Color border = Color(0xFFE3E8F2);
  static const Color textDark = Color(0xFF12131A);
  static const Color text = textDark;
  static const Color muted = Color(0xFF7A7E8B);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFA21A);

  static const Color darkBackground = Color(0xFF0E1118);
  static const Color darkCard = Color(0xFF171B24);
  static const Color darkSoftSurface = Color(0xFF202633);
  static const Color darkBorder = Color(0xFF2C3444);
  static const Color darkText = Color(0xFFF6F7FB);
  static const Color darkMuted = Color(0xFFA4ABBA);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldColor(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkCard : card;

  static Color softSurfaceColor(BuildContext context) =>
      isDark(context) ? darkSoftSurface : softSurface;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color titleColor(BuildContext context) =>
      isDark(context) ? darkText : textDark;

  static Color bodyColor(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color inputTextColor(BuildContext context) => titleColor(context);

  static Color dropdownColor(BuildContext context) => surfaceColor(context);

  static Color subtleIconColor(BuildContext context) => bodyColor(context);

  static Color overlayScrimColor(BuildContext context) =>
      Colors.black.withValues(alpha: isDark(context) ? 0.58 : 0.35);

  static BoxShadow softShadow({double alpha = 0.06, double blur = 18}) {
    return BoxShadow(
      color: Colors.black.withValues(alpha: alpha),
      blurRadius: blur,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow themedSoftShadow(
    BuildContext context, {
    double alpha = 0.06,
    double blur = 18,
  }) {
    return BoxShadow(
      color: Colors.black.withValues(alpha: isDark(context) ? alpha * 2.1 : alpha),
      blurRadius: blur,
      offset: const Offset(0, 8),
    );
  }

  static OutlineInputBorder inputBorder({Color color = border, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(TextTheme base, Brightness brightness) {
    final primaryText = brightness == Brightness.dark ? darkText : textDark;
    final secondaryText = brightness == Brightness.dark ? darkMuted : muted;

    final montserratTheme = base.apply(
      fontFamily: fontFamily,
      bodyColor: primaryText,
      displayColor: primaryText,
    );

    TextStyle? title(TextStyle? style) => style?.copyWith(
          fontFamily: titleFontFamily,
          color: primaryText,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.08,
        );

    return montserratTheme.copyWith(
      displayLarge: title(montserratTheme.displayLarge),
      displayMedium: title(montserratTheme.displayMedium),
      displaySmall: title(montserratTheme.displaySmall),
      headlineLarge: title(montserratTheme.headlineLarge)?.copyWith(fontSize: 36),
      headlineMedium: title(montserratTheme.headlineMedium)?.copyWith(fontSize: 30),
      headlineSmall: title(montserratTheme.headlineSmall)?.copyWith(fontSize: 26),
      titleLarge: title(montserratTheme.titleLarge)?.copyWith(fontSize: 28),
      titleMedium: montserratTheme.titleMedium?.copyWith(
        color: primaryText,
        fontSize: 18,
        height: 1.18,
        fontWeight: FontWeight.w800,
      ),
      titleSmall: montserratTheme.titleSmall?.copyWith(
        color: primaryText,
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: montserratTheme.bodyLarge?.copyWith(
        color: primaryText,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: montserratTheme.bodyMedium?.copyWith(
        color: secondaryText,
        fontSize: 14,
        height: 1.42,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: montserratTheme.bodySmall?.copyWith(
        color: secondaryText,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: montserratTheme.labelLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  static ThemeData light() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: teal,
        surface: card,
      ),
    );

    return _buildTheme(baseTheme, Brightness.light);
  }

  static ThemeData dark() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: teal,
        surface: darkCard,
      ),
    );

    return _buildTheme(baseTheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ThemeData baseTheme, Brightness brightness) {
    final isDarkMode = brightness == Brightness.dark;
    final scaffold = isDarkMode ? darkBackground : background;
    final surface = isDarkMode ? darkCard : card;
    final soft = isDarkMode ? darkSoftSurface : softSurface;
    final outline = isDarkMode ? darkBorder : border;
    final title = isDarkMode ? darkText : textDark;
    final secondary = isDarkMode ? darkMuted : muted;

    return baseTheme.copyWith(
      cardColor: surface,
      canvasColor: scaffold,
      dividerColor: outline,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.05),
      textTheme: _textTheme(baseTheme.textTheme, brightness),
      primaryTextTheme: _textTheme(baseTheme.primaryTextTheme, brightness).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: title,
        iconTheme: IconThemeData(color: title),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: title,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: soft,
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: secondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: secondary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: inputBorder(color: Colors.transparent, width: 0),
        enabledBorder: inputBorder(color: Colors.transparent, width: 0),
        focusedBorder: inputBorder(color: primary, width: 1.25),
        errorBorder: inputBorder(color: danger.withValues(alpha: 0.55)),
        focusedErrorBorder: inputBorder(color: danger, width: 1.25),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: outline),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          color: title,
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: TextStyle(
          color: secondary,
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      iconTheme: IconThemeData(color: title),
      listTileTheme: ListTileThemeData(
        textColor: title,
        iconColor: secondary,
        subtitleTextStyle: TextStyle(
          color: secondary,
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        titleTextStyle: TextStyle(
          color: title,
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: title,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: soft,
          border: inputBorder(color: Colors.transparent, width: 0),
          enabledBorder: inputBorder(color: Colors.transparent, width: 0),
          focusedBorder: inputBorder(color: primary, width: 1.25),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          color: title,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.24),
        selectionHandleColor: primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return secondary.withValues(alpha: 0.55);
          }
          return title;
        }),
        todayForegroundColor: WidgetStateProperty.all(primary),
        todayBorder: BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDarkMode ? darkSoftSurface : textDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
