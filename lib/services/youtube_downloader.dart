import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoMetadata {
  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;

  VideoMetadata({
    required this.id,
    required this.title,
    required this.author,
    this.duration,
    required this.thumbnailUrl,
  });

  String get durationFormatted {
    if (duration == null) return "00:00";
    final minutes = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}

class YouTubeDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Extracts metadata for a single video
  Future<VideoMetadata> getVideoInfo(String url) async {
    final video = await _yt.videos.get(url);
    return VideoMetadata(
      id: video.id.value,
      title: video.title,
      author: video.author,
      duration: video.duration,
      thumbnailUrl: video.thumbnails.highResUrl,
    );
  }

  /// Extracts all videos if URL is a playlist
  Future<List<VideoMetadata>> getPlaylistVideos(String playlistUrl) async {
    final List<VideoMetadata> results = [];
    final playlist = await _yt.playlists.get(playlistUrl);
    await for (final video in _yt.playlists.getVideos(playlist.id)) {
      results.add(
        VideoMetadata(
          id: video.id.value,
          title: video.title,
          author: video.author,
          duration: video.duration,
          thumbnailUrl: video.thumbnails.highResUrl,
        ),
      );
    }
    return results;
  }

  /// Request Android storage permissions
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // For Android 13+ audio permission
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;
    }
    return true;
  }

  /// Finds or creates public Download/SonicPulse folder on Android
  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download/SonicPulse');
      if (await downloadDir.exists()) {
        return downloadDir;
      }
      try {
        return await downloadDir.create(recursive: true);
      } catch (_) {
        // Fallback to app directory if public Downloads is restricted
      }
    }
    final extDir = await getExternalStorageDirectory();
    final sonicDir = Directory('${extDir?.path}/SonicPulse');
    if (!await sonicDir.exists()) {
      await sonicDir.create(recursive: true);
    }
    return sonicDir;
  }

  /// Downloads high quality audio stream directly to device
  Future<File> downloadAudio({
    required VideoMetadata video,
    String? subfolderName,
    required Function(double percent, String status) onProgress,
  }) async {
    onProgress(0.0, "Fetching audio streams...");

    final manifest = await _yt.videos.streamsClient.getManifest(video.id);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    final baseDir = await getDownloadDirectory();
    Directory targetDir = baseDir;

    if (subfolderName != null && subfolderName.isNotEmpty) {
      final cleanSub = subfolderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      targetDir = Directory('${baseDir.path}/$cleanSub');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }

    // Clean file name
    final safeTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = "${targetDir.path}/$safeTitle.mp3";
    final file = File(filePath);

    final stream = _yt.videos.streamsClient.get(audioStreamInfo);
    final output = file.openWrite();

    final totalBytes = audioStreamInfo.size.totalBytes;
    var downloadedBytes = 0;

    onProgress(0.05, "Downloading high-speed stream...");

    await for (final chunk in stream) {
      downloadedBytes += chunk.length;
      output.add(chunk);
      final percent = totalBytes > 0 ? (downloadedBytes / totalBytes) : 0.0;
      onProgress(percent, "Downloading: ${(percent * 100).toStringAsFixed(1)}%");
    }

    await output.flush();
    await output.close();

    onProgress(1.0, "Complete!");
    return file;
  }

  void dispose() {
    _yt.close();
  }
}
