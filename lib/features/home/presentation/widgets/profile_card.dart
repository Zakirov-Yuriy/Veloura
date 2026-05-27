import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    if (currentPhotoIndex >= total - 1) {
      return;
    }

    setState(() {
      currentPhotoIndex++;
    });
  }

  void previousPhoto() {
    if (currentPhotoIndex <= 0) {
      return;
    }

    setState(() {
      currentPhotoIndex--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos =
        List<String>.from(widget.profile['photoUrls'] ?? []);

    final currentPhoto = photos.isEmpty
        ? null
        : photos[currentPhotoIndex];

    final isOnline = widget.profile['isOnline'] == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: currentPhoto != null
                ? CachedNetworkImage(
                    imageUrl: currentPhoto,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      size: 96,
                    ),
                  ),
          ),

          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.translucent,
                    onTap: previousPhoto,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.translucent,
                    onTap: () {
                      nextPhoto(photos.length);
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          if (photos.length > 1)
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: List.generate(
                  photos.length,
                  (index) {
                    final isActive =
                        index == currentPhotoIndex;

                    return Expanded(
                      child: Container(
                        height: 4,
                        margin:
                            const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white38,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.profile['name']}, ${widget.profile['age']}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Онлайн' : 'Не в сети',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.profile['city'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.profile['bio'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
