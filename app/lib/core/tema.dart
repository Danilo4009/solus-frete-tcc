import 'package:flutter/material.dart';

/// Identidade visual do Solus Frete.
class Cores {
  static const Color primaria = Color(0xFF12467A);
  static const Color primariaEscura = Color(0xFF0B2F53);
  static const Color destaque = Color(0xFFF2A03D);
  static const Color sucesso = Color(0xFF1E8E5A);
  static const Color alerta = Color(0xFFC8502F);
  static const Color fundo = Color(0xFFF4F6F9);
  static const Color superficie = Colors.white;
  static const Color textoFraco = Color(0xFF6B7684);
  static const Color borda = Color(0xFFE1E6ED);
}

/// Tema enxuto de proposito: usa apenas subtemas estaveis entre versoes do
/// Flutter. O visual de cartoes e campos e aplicado pelos widgets em
/// core/widgets, evitando APIs de tema que mudaram de nome recentemente
/// (CardTheme/CardThemeData, InputDecorationTheme/InputDecorationThemeData).
ThemeData construirTema() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Cores.primaria,
      primary: Cores.primaria,
      secondary: Cores.destaque,
      surface: Cores.superficie,
    ),
    scaffoldBackgroundColor: Cores.fundo,
    // AppBarTheme e InputDecorationTheme continuam aceitos pelo ThemeData
    // (as classes novas herdam das antigas). Se alguma versao do Flutter
    // reclamar, basta remover estes dois blocos: o app continua funcionando.
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.superficie,
      foregroundColor: Cores.primariaEscura,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Cores.primariaEscura,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.primaria, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Cores.primaria,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Cores.primaria),
        foregroundColor: Cores.primaria,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
