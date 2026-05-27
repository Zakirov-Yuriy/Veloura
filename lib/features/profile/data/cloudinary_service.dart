import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/cloudinary_constants.dart';

class CloudinaryService {
  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] =
        CloudinaryConstants.uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();

    final responseData =
        await response.stream.bytesToString();

    final decodedData =
        jsonDecode(responseData);

    if (response.statusCode == 200) {
      return decodedData['secure_url'];
    }

    throw Exception(
      decodedData['error']['message'],
    );
  }
}