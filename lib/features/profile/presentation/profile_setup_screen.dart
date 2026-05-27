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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: isLoading ? null : pickAndUploadImage,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final hasLocalImage = index < selectedImages.length;
                  final hasUploadedImage = index < uploadedPhotoUrls.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      image: hasLocalImage
                          ? DecorationImage(
                              image: FileImage(selectedImages[index]),
                              fit: BoxFit.cover,
                            )
                          : hasUploadedImage
                              ? DecorationImage(
                                  image: NetworkImage(uploadedPhotoUrls[index]),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: !hasLocalImage && !hasUploadedImage
                        ? const Icon(Icons.add_a_photo)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Возраст',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(
                labelText: 'Пол',
              ),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: lookingFor,
              decoration: const InputDecoration(
                labelText: 'Кого ищу',
              ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Возраст от',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Возраст до',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'Город',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'О себе',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Сохранить профиль'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}