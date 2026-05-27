import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/models/profile_model.dart';
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

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF4F7B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Мой профиль',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фотографии',
              style: TextStyle(
                color: Colors.black,
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
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFEAEAEA),
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
                            color: Color(0xFFB8B8B8),
                            size: 30,
                          )
                        : null,
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            _ProfileField(
              controller: nameController,
              hint: 'Имя',
            ),

            const SizedBox(height: 14),

            _ProfileField(
              controller: ageController,
              hint: 'Возраст',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: gender,
              decoration: _inputDecoration('Пол'),
              items: const [
                DropdownMenuItem(
                  value: 'male',
                  child: Text('Мужчина'),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text('Женщина'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  gender = value;
                });
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: lookingFor,
              decoration: _inputDecoration('Кого ищу'),
              items: const [
                DropdownMenuItem(
                  value: 'male',
                  child: Text('Мужчину'),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text('Женщину'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  lookingFor = value;
                });
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _ProfileField(
                    controller: minAgeController,
                    hint: 'Возраст от',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileField(
                    controller: maxAgeController,
                    hint: 'Возраст до',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _ProfileField(
              controller: cityController,
              hint: 'Город',
            ),

            const SizedBox(height: 14),

            _ProfileField(
              controller: bioController,
              hint: 'О себе',
              maxLines: 5,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Сохранить профиль',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFFB8B8B8),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 16,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFFE8E8E8),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFFFF4F7B),
      ),
    ),
  );
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.black,
      ),
      decoration: _inputDecoration(hint),
    );
  }
}