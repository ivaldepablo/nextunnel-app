import 'package:flutter/material.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({
    this.idleColor,
    this.connectedColor,
    this.disconnectedColor,
  });

  final Color? idleColor;
  final Color? connectedColor;
  final Color? disconnectedColor;

  static const ConnectionButtonTheme light = ConnectionButtonTheme(
    idleColor: Color(0xFF6366f1),
    connectedColor: Color(0xFF22c55e),
    disconnectedColor: Color(0xFFef4444),
  );

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
    Color? disconnectedColor,
  }) =>
      ConnectionButtonTheme(
        idleColor: idleColor ?? this.idleColor,
        connectedColor: connectedColor ?? this.connectedColor,
        disconnectedColor: disconnectedColor ?? this.disconnectedColor,
      );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(covariant ThemeExtension<ConnectionButtonTheme>? other, double t) {
    if (other is! ConnectionButtonTheme) {
      return this;
    }
    return ConnectionButtonTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
      disconnectedColor: Color.lerp(disconnectedColor, other.disconnectedColor, t),
    );
  }
}
