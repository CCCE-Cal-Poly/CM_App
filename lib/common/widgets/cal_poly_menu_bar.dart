import 'package:flutter/material.dart';

class CalPolyMenuBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CalPolyMenuBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final barHeight = (screenHeight * 0.06).clamp(36.0, 52.0);

    return SizedBox(
      height: barHeight,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(
          padding: EdgeInsets.only(left: barHeight * 0.08),
          child: Image.asset(
            'assets/icons/cal_poly_white.png',
            height: barHeight * 0.72,
            fit: BoxFit.contain,
          ),
        ),
        IconButton(
          padding: EdgeInsets.only(right: barHeight * 0.06),
          iconSize: barHeight * 0.52,
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ]),
    );
  }
}
