import 'package:get/get.dart';

class YouTubePlayerTileController extends GetxController {
  final RxBool isLoading = true.obs;

  final String videoUrl;
  final String videoId;
  final String windowId;
  final int? refreshKey;
  final bool autoplay;
  final bool showControls;
  final bool showInfo;

  YouTubePlayerTileController({
    required this.videoUrl,
    required this.videoId,
    required this.windowId,
    this.refreshKey,
    this.autoplay = true,
    this.showControls = true,
    this.showInfo = true,
  });

  void setLoading(bool loading) {
    isLoading.value = loading;
  }
}
