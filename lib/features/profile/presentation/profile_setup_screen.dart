import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/models/profile_model.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/widgets/glow_field.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/cloudinary_provider.dart';
import 'providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends ConsumerState<ProfileSetupScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final bioController = TextEditingController();
  final cityController = TextEditingController();

  List<File> selectedImages = [];
  List<String> uploadedPhotoUrls = [];

  final imagePicker = ImagePicker();

  String gender = 'male';
  String lookingFor = 'female';
  bool isLoading = false;
  bool isProfileLoaded = false;

  final minAgeController = TextEditingController(text: '18');
  final maxAgeController = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return;
    }

    final data = doc.data()!;

    nameController.text = data['name'] ?? '';
    ageController.text = data['age']?.toString() ?? '';
    bioController.text = data['bio'] ?? '';
    cityController.text = data['city'] ?? '';
    gender = data['gender'] ?? 'male';
    lookingFor = data['lookingFor'] ?? 'female';
    minAgeController.text = data['minAge']?.toString() ?? '18';
    maxAgeController.text = data['maxAge']?.toString() ?? '60';

    uploadedPhotoUrls =
        List<String>.from(data['photoUrls'] ?? []);

    setState(() {
      isProfileLoaded = true;
    });
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final profile = ProfileModel(
        uid: user.uid,
        name: nameController.text.trim(),
        age: int.tryParse(ageController.text.trim()) ?? 18,
        gender: gender,
        bio: bioController.text.trim(),
        city: cityController.text.trim(),
        photoUrls: uploadedPhotoUrls.take(6).toList(),
        lookingFor: lookingFor,
        minAge: int.tryParse(minAgeController.text.trim()) ?? 18,
        maxAge: int.tryParse(maxAgeController.text.trim()) ?? 60,
      );

      await ref
          .read(profileRepositoryProvider)
          .saveProfile(profile);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    final pickedFiles = await imagePicker.pickMultiImage(
      imageQuality: 75,
    );

    if (pickedFiles.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final files =
          pickedFiles.map((e) => File(e.path)).toList();

      final uploadedUrls = <String>[];

      for (final file in files) {
        final imageUrl = await ref
            .read(cloudinaryServiceProvider)
            .uploadImage(file);

        uploadedUrls.add(imageUrl);
      }

      setState(() {
        selectedImages = files;
        uploadedPhotoUrls = uploadedUrls;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    bioController.dispose();
    cityController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    super.dispose();
  }

  // Заголовок секции в фирменном золотом стиле.
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gold = Color(0xFFD4AF37);
    const darkBg = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: darkBg,
      body: LuxuryScreen(
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  l10n.myProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.photos,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: isLoading ? null : pickAndUploadImage,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final hasLocalImage =
                      index < selectedImages.length;

                  final hasUploadedImage =
                      index < uploadedPhotoUrls.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3A3A3A),
                      ),
                      image: hasLocalImage
                          ? DecorationImage(
                              image:
                                  FileImage(selectedImages[index]),
                              fit: BoxFit.cover,
                            )
                          : hasUploadedImage
                              ? DecorationImage(
                                  image: NetworkImage(
                                    uploadedPhotoUrls[index],
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: !hasLocalImage &&
                            !hasUploadedImage
                        ? const Icon(
                            Icons.add_a_photo,
                            color: Color(0xFFD4AF37),
                            size: 30,
                          )
                        : null,
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            _sectionLabel(l10n.nameCaps),
            const SizedBox(height: 8),
            _ProfileField(
              controller: nameController,
              hint: l10n.name,
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.ageCaps),
            const SizedBox(height: 8),
            _ProfileField(
              controller: ageController,
              hint: l10n.ageField,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.iAmCaps),
            const SizedBox(height: 8),
            GlowField(
              builder: (focusNode) => DropdownButtonFormField<String>(
                focusNode: focusNode,
                value: gender,
                decoration: _inputDecoration(l10n.gender).copyWith(
                  enabledBorder: transparentInputBorder(),
                  focusedBorder: transparentInputBorder(),
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(
                  color: Colors.white,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(l10n.male),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(l10n.female),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    gender = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.lookingForCaps),
            const SizedBox(height: 8),
            GlowField(
              builder: (focusNode) => DropdownButtonFormField<String>(
                focusNode: focusNode,
                value: lookingFor,
                decoration: _inputDecoration(l10n.lookingForField).copyWith(
                  enabledBorder: transparentInputBorder(),
                  focusedBorder: transparentInputBorder(),
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(
                  color: Colors.white,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(l10n.manAccusative),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(l10n.womanAccusative),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    lookingFor = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.partnerAgeCaps),
            const SizedBox(height: 8),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      minAgeController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      maxAgeController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    rangeTrackShape: const _GradientRangeSliderTrackShape(),
                    inactiveTrackColor: const Color(0xFF3A3A3A),
                  ),
                  child: RangeSlider(
                    values: RangeValues(
                      double.parse(minAgeController.text),
                      double.parse(maxAgeController.text),
                    ),
                    min: 18,
                    max: 100,
                    onChanged: (RangeValues values) {
                      setState(() {
                        minAgeController.text = values.start.toInt().toString();
                        maxAgeController.text = values.end.toInt().toString();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.yourCityCaps),
            const SizedBox(height: 8),
            _ProfileField(
              controller: cityController,
              hint: l10n.cityField,
            ),

            const SizedBox(height: 14),

            _sectionLabel(l10n.aboutCaps),
            const SizedBox(height: 8),
            _ProfileField(
              controller: bioController,
              hint: l10n.aboutField,
              maxLines: 5,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: const Color(0xFF0F0F0F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F0F0F)),
                        ),
                      )
                    : Text(
                        l10n.saveProfile,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return luxuryInputDecoration(hint);
}

class _GradientRangeSliderTrackShape extends RangeSliderTrackShape {
  const _GradientRangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 5;
    const thumbRadius = 12.0;
    final trackLeft = offset.dx + thumbRadius;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 2 * thumbRadius;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Рисуем неактивную часть слева
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, startThumbCenter.dx - rect.left, rect.height),
        const Radius.circular(2.5),
      ),
      inactivePaint,
    );

    // Рисуем активную часть с градиентом
    final activeRect = Rect.fromLTWH(
      startThumbCenter.dx,
      rect.top,
      endThumbCenter.dx - startThumbCenter.dx,
      rect.height,
    );

    final gradient = LinearGradient(
      colors: const [
        Color(0xFFFF4F7B),
        Color(0xFFD4AF37),
      ],
    ).createShader(activeRect);

    final gradientPaint = Paint()
      ..shader = gradient;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, const Radius.circular(2.5)),
      gradientPaint,
    );

    // Рисуем неактивную часть справа
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(endThumbCenter.dx, rect.top, rect.right - endThumbCenter.dx, rect.height),
        const Radius.circular(2.5),
      ),
      inactivePaint,
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GlowField(
      builder: (focusNode) => TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: _inputDecoration(hint).copyWith(
          enabledBorder: transparentInputBorder(),
          focusedBorder: transparentInputBorder(),
        ),
      ),
    );
  }
}
