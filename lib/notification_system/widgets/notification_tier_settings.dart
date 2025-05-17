// lib/notification_system/widgets/notification_tier_settings.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/notification_config.dart';
import '../services/notification_service.dart';

class NotificationTierSettings extends StatelessWidget {
  const NotificationTierSettings({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();
    
    return Obx(() {
      final currentConfig = notificationService.config;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notification History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Tier selection
          Text(
            'License Tier',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildTierSelectionCards(context, notificationService, currentConfig),
          
          const SizedBox(height: 24),
          
          // Custom limit option
          Text(
            'Custom Limit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildCustomLimitSlider(context, notificationService, currentConfig),
        ],
      );
    });
  }
  
  Widget _buildTierSelectionCards(
    BuildContext context, 
    NotificationService service, 
    NotificationConfig currentConfig
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildTierCard(
          context: context,
          title: 'Basic',
          description: 'Only 1 notification',
          isSelected: currentConfig.tier == NotificationTier.basic,
          onTap: () => service.setTier(NotificationTier.basic),
        ),
        _buildTierCard(
          context: context,
          title: 'Standard',
          description: 'Up to 20 notifications',
          isSelected: currentConfig.tier == NotificationTier.standard,
          onTap: () => service.setTier(NotificationTier.standard),
        ),
        _buildTierCard(
          context: context,
          title: 'Premium',
          description: 'Up to 100 notifications',
          isSelected: currentConfig.tier == NotificationTier.premium,
          onTap: () => service.setTier(NotificationTier.premium),
        ),
        _buildTierCard(
          context: context,
          title: 'Unlimited',
          description: 'No limit',
          isSelected: currentConfig.tier == NotificationTier.unlimited,
          onTap: () => service.setTier(NotificationTier.unlimited),
        ),
      ],
    );
  }
  
  Widget _buildTierCard({
    required BuildContext context,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomLimitSlider(
    BuildContext context, 
    NotificationService service, 
    NotificationConfig currentConfig
  ) {
    return Column(
      children: [
        Slider(
          value: currentConfig.maxNotifications == -1 
              ? 50 // Default value for unlimited
              : currentConfig.maxNotifications.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: currentConfig.maxNotifications == -1 
              ? 'Unlimited' 
              : currentConfig.maxNotifications.toString(),
          onChanged: (value) {
            service.setMaxNotifications(value.toInt());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1', style: TextStyle(fontSize: 12)),
            Text(
              currentConfig.maxNotifications == -1 
                  ? 'Unlimited' 
                  : currentConfig.maxNotifications.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text('100', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => service.setTier(NotificationTier.unlimited),
          child: const Text('Set Unlimited'),
        ),
      ],
    );
  }
}