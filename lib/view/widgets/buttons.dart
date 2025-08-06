import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Buttons extends StatefulWidget {
  const Buttons({
    super.key,
    required this.text,
    required this.color,
    required this.height,
    required this.width,
    required this.radius,
  });
  final double height;
  final double width;
  final BorderRadius radius;
  final String text;
  final Color color;

  @override
  State<Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<Buttons> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        color: widget.color,
      ),
      child: Text(
        widget.text,
        style: GoogleFonts.dmSans(
          textStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
