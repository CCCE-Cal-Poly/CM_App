import 'package:ccce_application/common/theme/theme.dart';
import 'package:flutter/material.dart';

class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;

  const GoldAppBar({
    Key? key,
    this.title,
    this.titleTextStyle,
    this.leading,
    this.actions,
    this.height = kToolbarHeight,
  }) : super(key: key);

  double _scaledHeightFromWindow() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenHeight = view.physicalSize.height / view.devicePixelRatio;
    final proportional = (screenHeight * 0.018).clamp(14.0, 24.0) as double;
    return height == kToolbarHeight ? proportional : height;
  }

  double _scaledHeightFromContext(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final proportional = (screenHeight * 0.018).clamp(14.0, 24.0) as double;
    return height == kToolbarHeight ? proportional : height;
  }

  @override
  Size get preferredSize => Size.fromHeight(_scaledHeightFromWindow());

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _scaledHeightFromContext(context),
      title: title != null ? Text(title!, style: titleTextStyle) : null,
      leading: leading,
      actions: actions,
      flexibleSpace: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightGold, // Left color
              AppColors.darkGold, // Start of right gradient
              AppColors.lightGold, // End of right gradient (matches left)
            ],
            stops: [
              0.5, // Left side ends at 50%
              0.5, // Right side gradient starts at 50%
              1.0, // Right side gradient ends at 100%
            ],
          ).createShader(bounds);
        },
        child: Container(
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
    );
  }
}
