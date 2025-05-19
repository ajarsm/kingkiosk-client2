import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoCallView extends StatelessWidget {
  const VideoCallView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              'Video Call Functionality Removed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This functionality has been temporarily disabled while we upgrade to a new system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('Return to Previous Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
