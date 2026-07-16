import 'package:flutter/material.dart';

/// Points de rupture (breakpoints) de l'application.
class Breakpoints {
  /// En dessous : téléphone (plein écran).
  static const double mobile = 600;

  /// Entre [mobile] et [desktop] : tablette.
  static const double desktop = 1024;

  /// Largeur maximale du contenu sur grand écran (cadre centré).
  static const double content = 600;
}

/// Helpers de taille d'écran accessibles depuis le [BuildContext].
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Renvoie l'une des trois valeurs selon la classe de l'écran.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}

/// Centre et borne en largeur son [child] sur les grands écrans.
/// Sur mobile (largeur disponible <= [maxWidth]), se comporte comme un
/// passe-plat : la mise en page téléphone reste strictement identique.
class ResponsiveCenter extends StatelessWidget {
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const ResponsiveCenter({
    super.key,
    this.maxWidth = Breakpoints.content,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Cadre responsive global appliqué à toute l'application via
/// `MaterialApp.builder`. Sur grand écran, l'app est centrée dans une colonne
/// de largeur [maxWidth] sur un fond neutre, façon application tablette ;
/// sur téléphone, l'affichage est inchangé (plein écran).
class ResponsiveAppFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color sideColor;

  const ResponsiveAppFrame({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.content,
    this.sideColor = const Color(0xFFDADEE6),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return ColoredBox(
          color: sideColor,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
