import 'package:flutter/material.dart';

import '../theme.dart';

class RestaurantLogo extends StatelessWidget {
  final String? logoUrl;
  final String restaurantName;
  final double size;
  final BorderRadius borderRadius;
  final bool isCircular;

  const RestaurantLogo({
    super.key,
    required this.logoUrl,
    required this.restaurantName,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5D5C8), Color(0xFFC7DEC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: isCircular
            ? BorderRadius.circular(size / 2)
            : borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        restaurantName.trim().isNotEmpty
            ? restaurantName.trim()[0].toUpperCase()
            : 'R',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: AppColors.marronFonce.withValues(alpha: 0.55),
          fontSize: size * 0.42,
        ),
      ),
    );

    if (logoUrl == null || logoUrl!.trim().isEmpty) {
      return placeholder;
    }

    final image =
        logoUrl!.startsWith('http://') || logoUrl!.startsWith('https://')
        ? Image.network(
            logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          )
        : Image.asset(
            logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          );

    return ClipRRect(
      borderRadius: isCircular ? BorderRadius.circular(size / 2) : borderRadius,
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
