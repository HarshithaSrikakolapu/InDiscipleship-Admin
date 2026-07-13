import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/sidebar.dart';
import 'widgets/top_app_bar.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 992; // laptop and desktop

    return Scaffold(
      drawer: isDesktop ? null : Sidebar(navigationShell: navigationShell),
      body: Row(
        children: [
          if (isDesktop) Sidebar(navigationShell: navigationShell),
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (ctx) => TopAppBar(
                    showMenuIcon: !isDesktop,
                    onMenuPressed: () {
                      if (!isDesktop) {
                        Scaffold.of(ctx).openDrawer();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: navigationShell,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
