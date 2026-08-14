import 'dart:io';

import 'package:lacos_app/core/domain/exceptions/photo_upload_exception.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Faz upload de um arquivo local como [ParseFile] no Parse Server.
Future<ParseFile?> uploadParsePhotoFile(String? photoPath) async {
  if (photoPath == null || photoPath.isEmpty) {
    return null;
  }

  final file = File(photoPath);
  if (!await file.exists()) {
    throw const PhotoUploadException();
  }

  final parseFile = ParseFile(file);
  final response = await parseFile.save();
  if (!response.success) {
    throw const PhotoUploadException();
  }

  return parseFile;
}

/// Lê a URL pública de um campo `photo` (ParseFile) em um [ParseObject].
String? parsePhotoUrl(ParseObject object) {
  final photo = object.get<dynamic>('photo');
  if (photo == null) {
    return null;
  }

  return photo.url as String?;
}
