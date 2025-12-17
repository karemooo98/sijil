import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/config/app_config.dart';
import '../../controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildProfileAvatar(BuildContext context, String? photo, {double size = 100}) {
    final double radius = size / 2;
    
    if (photo != null && photo.trim().isNotEmpty && photo.trim() != 'null') {
      String imageUrl = photo.trim();
      
      // If photo is a relative URL, prepend base URL
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        if (!imageUrl.startsWith('/')) {
          imageUrl = '/$imageUrl';
        }
        imageUrl = '${AppConfig.baseUrl}$imageUrl';
      }
      
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.white,
              child: Icon(
                Symbols.account_circle,
                size: size * 0.7,
                color: Colors.grey.shade400,
              ),
            );
          },
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.white,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            );
          },
        ),
      );
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Icon(
        Symbols.account_circle,
        size: size * 0.7,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // Fetch data every time we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProfile();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.profile.value;
        if (user == null) {
          return Column(
            children: <Widget>[
              AppBar(
                title: const Text('Profile'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Symbols.person, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Profile not found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (controller.errorMessage.value != null &&
            controller.errorMessage.value!.isNotEmpty) {
          return Column(
            children: <Widget>[
              AppBar(
                title: const Text('Profile'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        controller.errorMessage.value ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          slivers: <Widget>[
            // App Bar with gradient
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
          child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const SizedBox(height: 20),
              // Avatar
                        Obx(
                          () => Stack(
                            alignment: Alignment.bottomRight,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildProfileAvatar(
                                  context,
                                  controller.profile.value?.photo,
                                  size: 100,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: controller.isUploadingImage.value
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        )
                                      : Icon(Symbols.camera_alt, color: primaryColor, size: 20),
                                  onPressed: controller.isUploadingImage.value
                                      ? null
                                      : () => controller.pickAndUploadImage(),
                                  tooltip: 'Change profile picture',
                                ),
                              ),
                            ],
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  user.name,
                  textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
              ),
                        const SizedBox(height: 12),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                ),
                decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  user.role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                    fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
                child: Padding(
                padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Quick Info Cards
                    Row(
                    children: <Widget>[
                        Expanded(
                          child: _buildQuickInfoCard(
                        context,
                        icon: Symbols.badge,
                            label: 'Employee #',
                        value: user.employeeNumber?.toString() ?? 'N/A',
                            color: Colors.blue,
                          ),
                      ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickInfoCard(
                            context,
                            icon: Symbols.check_circle,
                            label: 'Status',
                            value: user.isActive ? 'Active' : 'Inactive',
                            color: user.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Personal Information Card
                    _buildSectionCard(
                      context,
                      title: 'Personal Information',
                      icon: Symbols.person,
                      children: <Widget>[
                        _buildModernInfoRow(
                        context,
                        icon: Symbols.email,
                        label: 'Email',
                        value: user.email,
                      ),
                        const SizedBox(height: 16),
                        _buildModernInfoRow(
                          context,
                          icon: Symbols.phone,
                          label: 'Phone Number',
                          value: user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : 'Not set',
                          valueColor: user.phoneNumber?.isNotEmpty == true ? null : Colors.grey,
                        ),
                        if (user.onlineAttendanceMode != null && user.onlineAttendanceMode!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildModernInfoRow(
                            context,
                            icon: Symbols.access_time,
                            label: 'Attendance Mode',
                            value: user.onlineAttendanceMode!.replaceAll('_', ' ').toUpperCase(),
                          ),
                        ],
                        if (user.weekendDays.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildModernInfoRow(
                            context,
                            icon: Symbols.calendar_today,
                            label: 'Weekend Days',
                            value: user.weekendDays.join(', '),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Financial Information Card
                    _buildSectionCard(
                      context,
                      title: 'Financial Information',
                      icon: Symbols.account_balance,
                      children: <Widget>[
                        _buildModernInfoRow(
                        context,
                          icon: Symbols.account_balance,
                          label: 'Account Number',
                          value: user.accountNumber?.isNotEmpty == true ? user.accountNumber! : 'Not set',
                          valueColor: user.accountNumber?.isNotEmpty == true ? null : Colors.grey,
                      ),
                        const SizedBox(height: 16),
                        _buildModernInfoRow(
                        context,
                          icon: Symbols.wallet,
                          label: 'Wallet Number',
                          value: user.walletNumber?.isNotEmpty == true ? user.walletNumber! : 'Not set',
                          valueColor: user.walletNumber?.isNotEmpty == true ? null : Colors.grey,
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),
                    // ID Documents Card
                    _buildSectionCard(
                      context,
                      title: 'ID Documents',
                      icon: Symbols.badge,
                      children: <Widget>[
                        _buildDocumentRow(
                          context,
                          label: 'ID Card (Front)',
                          imageUrl: user.idPicFront,
                          onUpload: () => controller.uploadIdDocument('front'),
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentRow(
                          context,
                          label: 'ID Card (Back)',
                          imageUrl: user.idPicBack,
                          onUpload: () => controller.uploadIdDocument('back'),
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentRow(
                          context,
                          label: 'Residential ID (Front)',
                          imageUrl: user.residentialIdFront,
                          onUpload: () => controller.uploadResidentialId('front'),
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentRow(
                          context,
                          label: 'Residential ID (Back)',
                          imageUrl: user.residentialIdBack,
                          onUpload: () => controller.uploadResidentialId('back'),
                        ),
                      ],
              ),
              const SizedBox(height: 24),
              // Edit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed('/edit-profile'),
                        icon: const Icon(Symbols.edit, size: 20),
                        label: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ),
                ),
              ),
            ],
        );
      }),
    );
  }

  Widget _buildQuickInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, {
    required String label,
    String? imageUrl,
    required VoidCallback onUpload,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null')
                GestureDetector(
                  onTap: () {
                    // Show full image in dialog
                    showDialog(
      context: context,
                      builder: (BuildContext context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                            AppBar(
                              title: Text(label),
                              actions: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                ),
                            Expanded(
                              child: Image.network(
                                imageUrl.startsWith('http') 
                                    ? imageUrl 
                                    : '${AppConfig.baseUrl}${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}',
                                fit: BoxFit.contain,
                                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, size: 48, color: Colors.red),
                                  );
                  },
                ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 80,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl.startsWith('http') 
                            ? imageUrl 
                            : '${AppConfig.baseUrl}${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}',
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 80,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 32, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onUpload,
          icon: const Icon(Symbols.upload, size: 18),
          label: Text(imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null' ? 'Update' : 'Upload'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
    );
  }

}
