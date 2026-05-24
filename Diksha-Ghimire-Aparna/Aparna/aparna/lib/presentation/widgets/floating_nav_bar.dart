import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../main.dart';


class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalMargin = (size.width * 0.06).clamp(16.0, 32.0);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarItem(
            icon: Icons.local_hospital,
            label: 'Health',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            isCustomIcon: true,
          ),
          _NavBarItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

/// A vertical version of the NavBar designed specifically for Tablets & Desktops.
class SideNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SideNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Fixed width for the side navigation
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(4, 0), // Shadow to the right
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavBarItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
            isVertical: true,
          ),
          const SizedBox(height: 32),
          _NavBarItem(
            icon: Icons.local_hospital,
            label: 'Health',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
            isCustomIcon: true,
            isVertical: true,
          ),
          const SizedBox(height: 32),
          _NavBarItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
            isVertical: true,
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCustomIcon;
  final bool isVertical; // Added to support SideNavBar

  const _NavBarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCustomIcon = false,
    this.isVertical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isVertical ? 12 : (isSelected ? 20 : 16),
          vertical: isVertical ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: isVertical 
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(context),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(context),
              ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: isCustomIcon
            ? SvgPicture.asset(
                'assets/icons/rod_of_asclepius.svg',
                width: isSelected ? (isVertical ? 28 : 26) : 24,
                height: isSelected ? (isVertical ? 28 : 26) : 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                  BlendMode.srcIn,
                ),
              )
            : Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                size: isSelected ? (isVertical ? 28 : 26) : 24,
              ),
      ),
      if (isSelected || isVertical) ...[
        SizedBox(
          width: isVertical ? null : 10,
          height: isVertical ? 8 : null,
        ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: isVertical ? 12 : 15,
          ),
          child: Text(label),
        ),
      ],
    ];
  }
}

