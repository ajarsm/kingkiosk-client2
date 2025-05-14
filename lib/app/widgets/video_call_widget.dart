import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';

import '../services/mediasoup_service.dart';
import '../core/utils/notification_utils.dart';

class VideoCallWidget extends StatefulWidget {
  final String roomId;
  final String serverUrl;

  const VideoCallWidget({
    Key? key,
    required this.roomId,
    required this.serverUrl,
  }) : super(key: key);

  @override
  _VideoCallWidgetState createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  final MediasoupService _mediasoupService = Get.find<MediasoupService>();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupMediasoup();
  }

  Future<void> _setupMediasoup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_mediasoupService.localStream == null) {
        await _mediasoupService.createLocalStream();
      }

      await _mediasoupService.joinRoom(
        url: widget.serverUrl,
        roomId: widget.roomId,
        onJoinSuccess: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onJoinError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to join room: $error';
            });
            NotificationUtils.showError(
              message: 'Could not join video call room: $error',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
        NotificationUtils.showError(
          message: 'Video call setup error: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _mediasoupService.leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    return _buildCallWidget();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Setting up video call...'),
          SizedBox(height: 8),
          Text('Room: ${widget.roomId}', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('Connection Error', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(_errorMessage, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _setupMediasoup,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallWidget() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Remote videos
              Obx(() {
                final remoteRenderers = _mediasoupService.remoteRenderers;
                if (remoteRenderers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Waiting for others to join...'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: remoteRenderers.length == 1 ? 1 : 2,
                    childAspectRatio: 4 / 3,
                  ),
                  itemCount: remoteRenderers.length,
                  itemBuilder: (context, index) {
                    final renderer = remoteRenderers.values.elementAt(index);
                    final peerId = remoteRenderers.keys.elementAt(index);
                    return _buildVideoView(renderer, peerId);
                  },
                );
              }),

              // Local video preview (small overlay)
              Positioned(
                right: 16,
                bottom: 16,
                width: 120,
                height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: webrtc.RTCVideoView(
                      _mediasoupService.localRenderer,
                      objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Control bar
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Obx(() => _buildControlButton(
                icon: _mediasoupService.isAudioEnabled.value
                    ? Icons.mic
                    : Icons.mic_off,
                label: _mediasoupService.isAudioEnabled.value ? 'Mute' : 'Unmute',
                onPressed: _mediasoupService.toggleAudio,
              )),
              _buildControlButton(
                icon: Icons.call_end,
                label: 'End',
                backgroundColor: Colors.red,
                onPressed: () {
                  _mediasoupService.leaveRoom();
                  Navigator.of(context).pop();
                },
              ),
              Obx(() => _buildControlButton(
                icon: _mediasoupService.isVideoEnabled.value
                    ? Icons.videocam
                    : Icons.videocam_off,
                label: _mediasoupService.isVideoEnabled.value ? 'Hide' : 'Show',
                onPressed: _mediasoupService.toggleVideo,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoView(webrtc.RTCVideoRenderer renderer, String peerId) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Video
            webrtc.RTCVideoView(
              renderer,
              objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            // Peer name overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black45,
                child: Text(
                  'Participant $peerId',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RawMaterialButton(
          onPressed: onPressed,
          constraints: BoxConstraints(minWidth: 36.0, minHeight: 36.0),
          shape: CircleBorder(),
          fillColor: backgroundColor ?? Colors.white24,
          child: Icon(icon, color: Colors.white),
          padding: EdgeInsets.all(12),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}