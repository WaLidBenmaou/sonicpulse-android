import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import '../services/youtube_downloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final YouTubeDownloadService _downloadService = YouTubeDownloadService();

  bool _isLoadingPreview = false;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = "Ready";

  VideoMetadata? _currentVideo;
  List<VideoMetadata>? _playlistVideos;
  String? _lastDownloadedFile;

  @override
  void dispose() {
    _urlController.dispose();
    _downloadService.dispose();
    super.dispose();
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!.trim();
      _fetchPreview(data.text!.trim());
    }
  }

  Future<void> _fetchPreview(String url) async {
    if (!url.startsWith("http://") && !url.startsWith("https://")) return;

    setState(() {
      _isLoadingPreview = true;
      _currentVideo = null;
      _playlistVideos = null;
      _statusText = "Fetching video details...";
    });

    try {
      if (url.contains("list=")) {
        final videos = await _downloadService.getPlaylistVideos(url);
        setState(() {
          _playlistVideos = videos;
          _currentVideo = videos.isNotEmpty ? videos.first : null;
          _isLoadingPreview = false;
          _statusText = "Playlist loaded (${videos.length} tracks)";
        });
      } else {
        final video = await _downloadService.getVideoInfo(url);
        setState(() {
          _currentVideo = video;
          _isLoadingPreview = false;
          _statusText = "Ready to download";
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
        _statusText = "Error fetching video: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startDownload() async {
    if (_currentVideo == null && _playlistVideos == null) return;

    await _downloadService.requestStoragePermission();

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = "Starting download...";
    });

    try {
      if (_playlistVideos != null && _playlistVideos!.isNotEmpty) {
        // Download full playlist
        final total = _playlistVideos!.length;
        for (var i = 0; i < total; i++) {
          final video = _playlistVideos![i];
          setState(() {
            _statusText = "[${i + 1}/$total] Downloading: ${video.title}";
          });

          final file = await _downloadService.downloadAudio(
            video: video,
            subfolderName: "Playlist Downloads",
            onProgress: (pct, status) {
              setState(() {
                _progress = pct;
              });
            },
          );
          _lastDownloadedFile = file.path;
        }
        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _statusText = "✓ All ${total} tracks downloaded!";
        });
      } else if (_currentVideo != null) {
        // Single video
        final file = await _downloadService.downloadAudio(
          video: _currentVideo!,
          onProgress: (pct, status) {
            setState(() {
              _progress = pct;
              _statusText = status;
            });
          },
        );
        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _lastDownloadedFile = file.path;
          _statusText = "✓ Download complete!";
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = "Download error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _openFile(String path) {
    if (File(path).existsSync()) {
      OpenFile.open(path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Image.asset("assets/logo.png", width: 34, height: 34),
            const SizedBox(width: 12),
            const Text(
              "SonicPulse",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF38BDF8),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "YouTube Link",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Paste YouTube or Playlist URL...",
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF475569)),
                            ),
                          ),
                          onSubmitted: _fetchPreview,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pasteClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Paste", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loading Indicator
            if (_isLoadingPreview)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              ),

            // Video / Playlist Preview Card
            if (_currentVideo != null && !_isLoadingPreview)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: _currentVideo!.thumbnailUrl,
                            width: 120,
                            height: 75,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.black26),
                            errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentVideo!.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentVideo!.author,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _playlistVideos != null
                                    ? "Full Playlist (${_playlistVideos!.length} Tracks)"
                                    : "Duration: ${_currentVideo!.durationFormatted}",
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Action / Download Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: (_isDownloading || (_currentVideo == null && _playlistVideos == null))
                        ? null
                        : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      disabledBackgroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isDownloading
                          ? "Downloading..."
                          : (_playlistVideos != null
                              ? "⚡ Download Entire Playlist (${_playlistVideos!.length} Tracks)"
                              : "⚡ Download MP3 Now"),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (_lastDownloadedFile != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openFile(_lastDownloadedFile!),
                      icon: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8)),
                      label: const Text("Open Downloaded Track", style: TextStyle(color: Color(0xFF38BDF8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
