import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget laptop;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.laptop,
    required this.desktop,
  });

  // Mobile < 768
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  // Tablet 768 - 991
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 992;

  // Laptop 992 - 1200
  static bool isLaptop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 992 &&
      MediaQuery.of(context).size.width <= 1200;

  // Desktop > 1200
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1200;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    if (size.width > 1200) {
      return desktop;
    } else if (size.width >= 992) {
      return laptop;
    } else if (size.width >= 768) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
