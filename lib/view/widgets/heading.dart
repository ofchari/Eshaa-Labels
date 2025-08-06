import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HeadingText extends StatefulWidget {
  const HeadingText({
    super.key,
    required this.text,
    required this.color,
    required this.weight,
  });
  final String text;
  final Color color;
  final FontWeight weight;

  @override
  State<HeadingText> createState() => _HeadingTextState();
}

class _HeadingTextState extends State<HeadingText> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      style: GoogleFonts.dmSans(
        textStyle: TextStyle(
          fontSize: 21.sp,
          fontWeight: widget.weight,
          color: widget.color,
        ),
      ),
    );
  }
}
