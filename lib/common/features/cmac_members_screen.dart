import 'package:flutter/material.dart';
import 'package:ccce_application/common/theme/theme.dart';

class CmacMembersScreen extends StatelessWidget {
	final GlobalKey<ScaffoldState> scaffoldKey;

	const CmacMembersScreen({super.key, required this.scaffoldKey});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFFF0EFE6),
			body: SafeArea(
				child: Column(
					children: [
						Container(
							decoration: const BoxDecoration(
								color: AppColors.calPolyGreen,
								border: Border(
									bottom: BorderSide(color: AppColors.calPolyGold, width: 5),
								),
							),
							height: 84,
							child: Row(
								children: [
									IconButton(
										tooltip: 'Open menu',
										icon: const Icon(
											Icons.menu_rounded,
											color: Colors.white,
										),
										onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
									),
									const Expanded(
										child: Column(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												Text(
													'CMAC MEMBERS',
													textAlign: TextAlign.center,
													style: TextStyle(
														color: AppColors.welcomeLightYellow,
														fontFamily: 'SansSerifProSemiBold',
														fontSize: 25,
														letterSpacing: 1.2,
													),
												),
												SizedBox(height: 2),
												Text(
													'2025 - 2026',
													style: TextStyle(
														color: Colors.white,
														fontFamily: 'SansSerifPro',
														fontSize: 13,
														letterSpacing: 1.5,
													),
												),
											],
										),
									),
									const SizedBox(width: 56),
								],
							),
						),
						Expanded(
							child: LayoutBuilder(
								builder: (context, constraints) {
									final imageWidth = constraints.maxWidth > 980
										? 900.0
										: constraints.maxWidth - 32;

									return SingleChildScrollView(
										padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
										child: Center(
											child: Container(
												width: imageWidth,
												padding: const EdgeInsets.all(12),
												decoration: BoxDecoration(
													color: Colors.white,
													border: Border.all(
														color: AppColors.calPolyGreen,
														width: 2,
													),
													boxShadow: const [
														BoxShadow(
															color: Color(0x30000000),
															blurRadius: 12,
															offset: Offset(0, 5),
														),
													],
												),
												child: InteractiveViewer(
													boundaryMargin: const EdgeInsets.all(48),
													minScale: 1,
													maxScale: 4,
													child: Image.asset(
														'assets/2025-2026_CMAC_Members.png',
														fit: BoxFit.contain,
														width: imageWidth - 24,
														errorBuilder: (context, error, stackTrace) =>
															const Padding(
																padding: EdgeInsets.all(40),
																child: Text(
																	'Unable to load CMAC Members image',
																	style: TextStyle(
																		color: AppColors.calPolyGreen,
																		fontFamily: 'SansSerifPro',
																	),
																),
															),
													),
										),
									),
								),
										);
								},
							),
						),
					],
				),
			),
		);
	}
}
