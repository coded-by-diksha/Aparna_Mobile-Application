import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:aparna/l10n/app_localizations.dart';

class AdminFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminFloatingNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalMargin = (size.width * 0.04).clamp(12.0, 24.0);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          _AdminNavBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.home,
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _AdminNavBarItem(
            icon: Icons.article_outlined,
            selectedIcon: Icons.article,
            label: l10n.blogs,
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _AdminNavBarItem(
            icon: Icons.local_hospital_outlined,
            selectedIcon: Icons.local_hospital,
            label: l10n.clinics,
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _AdminNavBarItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: l10n.users,
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _AdminNavBarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.profile,
            isSelected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _AdminNavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavBarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
