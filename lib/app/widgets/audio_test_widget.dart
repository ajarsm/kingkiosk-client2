import 'package:flutter/material.dart';
import '../core/utils/sound_util.dart';

/// A simple widget to test the audio functionality
class AudioTestWidget extends StatelessWidget {
  const AudioTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Test the MediaKit audio implementation'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.error_outline),
                  label: Text('Error Sound'),
                  onPressed: () async {
                    await SoundUtil.playError();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Success Sound'),
                  onPressed: () async {
                    await SoundUtil.playSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.notifications),
                  label: Text('Notification'),
                  onPressed: () async {
                    await SoundUtil.playNotification();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.delete_outline),
                label: Text('Clear Audio Cache'),
                onPressed: () async {
                  await SoundUtil.clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audio cache cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
