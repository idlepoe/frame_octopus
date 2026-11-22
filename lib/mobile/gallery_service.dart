import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GalleryVideo {
  final String path, name, id;
  const GalleryVideo(this.path, this.name, this.id);
}

class GalleryService {
  static const channel = MethodChannel('frame_octopus/gallery');

  Future<List<GalleryVideo>> pick() async {
    final values = await channel.invokeListMethod<dynamic>('pickVideos') ?? [];
    return values.map((value) {
      final item = Map<String, dynamic>.from(value as Map);
      return GalleryVideo(
        item['path'] as String,
        item['name'] as String,
        item['id'] as String,
      );
    }).toList();
  }

  Future<void> save(String path) async {
    await channel.invokeMethod<dynamic>('save', {'path': path});
  }

  /// Only app-owned working folders are removed, before importing this session.
  Future<void> cleanPreviousSession() async {
    final cache = await getTemporaryDirectory();
    final support = await getApplicationSupportDirectory();
    for (final folder in [
      Directory(p.join(cache.path, 'frame_octopus_imports')),
      Directory(p.join(cache.path, 'frame_octopus_thumbnails')),
      Directory(p.join(cache.path, 'frame_octopus')),
      Directory(p.join(support.path, 'results')),
    ]) {
      if (await folder.exists()) await folder.delete(recursive: true);
    }
  }
}
