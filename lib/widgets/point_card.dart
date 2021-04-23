import 'package:flutter/material.dart';

class PointCard extends StatelessWidget {
  const PointCard({
    Key? key,
    required this.size,
    required this.points,
  }) : super(key: key);

  final Size size;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.shortestSide * 0.2,
      width: size.shortestSide* 0.2,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white, width: 2.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          "$points",
          style: TextStyle(
              color: (points >= 0) ? Colors.greenAccent : Colors.redAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
