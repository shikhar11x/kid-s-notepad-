import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cute {
  // Palette from the reference image
  static const bg = Color(0xFF5A1A6E);        // deep purple backdrop
  static const paper = Color(0xFFFFD9EC);     // pink page
  static const stripe = Color(0xFFFFC2E0);    // darker pink stripe
  static const frame = Color(0xFF4A4FB0);     // blue phone frame
  static const screenPink = Color(0xFFFFB3B8);// salmon inner bezel
  static const topBar = Color(0xFFFF6B6B);    // coral window bar
  static const dock = Color(0xFF9B4FB8);      // purple dock
  static const ink = Color(0xFF2A1240);       // outlines / text
  static const line = Color(0xFFFFC2E0);      // ruled lines
  static const star = Color(0xFFFFE07A);      // star yellow
  static const starCore = Color(0xFFFF6B8A);  // star center
  static const hot = Color(0xFFFF3D7F);       // active dock pink
  static const mint = Color(0xFF7ED9B5);

  static TextStyle title = GoogleFonts.baloo2(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: ink,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static TextStyle hint = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ink.withOpacity(0.35),
  );

  // Chunky outline used on almost every element for the sticker look
  static Border outline([double w = 2.5]) => Border.all(color: ink, width: w);
}