import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/config/app_config.dart';

class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    super.key,
    required this.userName,
    this.employeeNumber,
    this.userId,
    this.onTap,
    this.leading,
    this.trailing,
    this.subtitle,
    this.backgroundColor,
    this.avatarBackgroundColor,
    this.avatarTextColor,
    this.photo,
  });

  final String userName;
  final String? employeeNumber;
  final int? userId;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget? subtitle;
  final Color? backgroundColor;
  final Color? avatarBackgroundColor;
  final Color? avatarTextColor;
  final String? photo;

  String get _idLabel {
    if (employeeNumber != null && employeeNumber!.isNotEmpty) {
      return employeeNumber!;
    }
    return userId?.toString() ?? '?';
  }

  String get _userInitial {
    if (userName.isNotEmpty) {
      return userName[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color defaultAvatarBg = avatarBackgroundColor ?? primaryColor;
    final Color defaultAvatarText = avatarTextColor ?? Colors.white;
    final Color cardBg = backgroundColor ?? Colors.grey.shade50;

    Widget cardContent = Container(
      margin: EdgeInsets.only(bottom: 1.0.h),
      padding: EdgeInsets.symmetric(vertical: 1.0.h, horizontal: 1.5.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (leading != null) ...[
            leading!,
            SizedBox(width: 1.5.w),
          ] else
            _buildAvatar(context, defaultAvatarBg, defaultAvatarText),
          SizedBox(width: 1.2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Emp #$_idLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 1.1.h,
                      ),
                ),
                SizedBox(height: 0.2.h),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 1.4.h,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 0.5.h),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 1.2.w),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(1.5.h),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildAvatar(BuildContext context, Color bgColor, Color textColor) {
    // Debug: Print photo value
    // print('EmployeeCard photo: $photo for user: $userName');
    
    // Check if photo exists and is not empty
    if (photo != null && photo!.trim().isNotEmpty && photo!.trim() != 'null') {
      String imageUrl = photo!.trim();
      
      // If photo is a relative URL, prepend base URL
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        // Ensure URL starts with /
        if (!imageUrl.startsWith('/')) {
          imageUrl = '/$imageUrl';
        }
        imageUrl = '${AppConfig.baseUrl}$imageUrl';
      }
      
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 4.0.h,
          height: 4.0.h,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            // Fallback to initial if image fails to load
            return CircleAvatar(
              radius: 2.0.h,
              backgroundColor: bgColor,
              child: Text(
                _userInitial,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontSize: 1.6.h,
                ),
              ),
            );
          },
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return CircleAvatar(
              radius: 2.0.h,
              backgroundColor: bgColor,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            );
          },
        ),
      );
    }
    
    return CircleAvatar(
      radius: 2.0.h,
      backgroundColor: bgColor,
      child: Text(
        _userInitial,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 1.6.h,
        ),
      ),
    );
  }
}

