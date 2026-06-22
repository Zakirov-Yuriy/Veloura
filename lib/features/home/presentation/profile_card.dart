import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/i18n/bot_localization.dart';
import '../../../../core/theme/luxury_theme.dart';
import '../../../../core/utils/presence.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int currentPhotoIndex = 0;

  void nextPhoto(int total) {
    if (currentPhotoIndex >= total - 1) return;
    setState(() => currentPhotoIndex++);
  }

  void previousPhoto() {
    if (currentPhotoIndex <= 0) return;
    setState(() => currentPhotoIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = List<String>.from(widget.profile['photoUrls'] ?? []);
    final currentPhoto =
        photos.isEmpty ? null : photos[currentPhotoIndex];

    final isOnline = isUserOnline(widget.profile);

    // Локализованные имя и город (для живых юзеров вернутся как есть).
    final name = context.botField(widget.profile, 'name');
    final city = context.botField(widget.profile, 'city');
    final age = widget.profile['age'] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LuxuryColors.gold.withOpacity(0.12),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: currentPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: currentPhoto,
                      fit: BoxFit.cover,
                    )
                  : const ColoredBox(
                      color: Color(0xFF171717),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: LuxuryColors.gold,
                          size: 96,
                        ),
                      ),
                    ),
            ),

            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: previousPhoto,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => nextPhoto(photos.length),
                    ),
                  ),
                ],
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.transparent,
                      Colors.black.withOpacity(0.86),
                    ],
                  ),
                ),
              ),
            ),

            if (photos.length > 1)
              Positioned(
                right: 14,
                bottom: 18,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white54,
                    ),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    size: 18,
                  ),
                ),
              ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${name.isNotEmpty ? name : l10n.user}, $age',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.verified,
                        color: LuxuryColors.gold,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.46),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: Text(
                      isOnline ? l10n.online : l10n.offline,
                      style: TextStyle(
                        color: isOnline
                            ? LuxuryColors.online
                            : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ЗОЛОТАЯ РАМКА ПОВЕРХ ВСЕГО

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: LuxuryColors.gold.withOpacity(0.55),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
