import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Inline sandboxed video player with lazy play-tap initialization,
/// poster frame preview, progress scrubbing, and automatic audio pause on navigation/offscreen.
class SandboxedVideoPlayer extends StatefulWidget {
  final File videoFile;
  final File? thumbnailFile;
  final Duration? duration;
  final bool autoPlay;

  const SandboxedVideoPlayer({
    super.key,
    required this.videoFile,
    this.thumbnailFile,
    this.duration,
    this.autoPlay = false,
  });

  @override
  State<SandboxedVideoPlayer> createState() => _SandboxedVideoPlayerState();
}

class _SandboxedVideoPlayerState extends State<SandboxedVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoPlay) {
      _initializeAndPlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Watchpoint 2: Pause audio & video when app goes to background or becomes inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller != null && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Watchpoint 2: Immediately stop audio playback and release hardware decoders on dispose
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    super.dispose();
  }

  Future<void> _initializeAndPlay() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final controller = VideoPlayerController.file(widget.videoFile);
      await controller.initialize();
      controller.addListener(_onControllerUpdate);
      await controller.play();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Could not load video: $e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlayPause() {
    if (_controller == null) {
      _initializeAndPlay();
      return;
    }

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      if (_controller!.value.position >= _controller!.value.duration) {
        _controller!.seekTo(Duration.zero);
      }
      _controller!.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Error state
    if (_hasError) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade900),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 36, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _initializeAndPlay,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // 2. Initial / Not Initialized State (Poster Frame + Play Overlay)
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // Poster frame image if available
            if (widget.thumbnailFile != null && widget.thumbnailFile!.existsSync())
              Image.file(
                widget.thumbnailFile!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),

            // Subtle dark overlay
            Container(color: Colors.black26),

            // Top-left Video Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Short Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Duration Badge (bottom-right)
            if (widget.duration != null)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xBF000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(widget.duration!),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),

            // Play Button or Loading Indicator
            Center(
              child: _isInitializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: _initializeAndPlay,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    // 3. Active Playback State
    final val = _controller!.value;
    final aspectRatio = val.aspectRatio > 0 ? val.aspectRatio : (16 / 9);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: aspectRatio.clamp(0.5, 2.4),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),

              // Center quick play/pause button if controls visible
              if (_showControls)
                Center(
                  child: IconButton(
                    iconSize: 48,
                    icon: Icon(
                      val.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white.withAlpha(220),
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),

              // Bottom control bar
              if (_showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.deepPurpleAccent,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(val.position),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(val.duration),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
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
