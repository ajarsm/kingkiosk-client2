import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final RxBool isLoading;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr, // Add explicit text direction
      alignment: Alignment.center, // Use Alignment instead of AlignmentDirectional
      children: [
        child,
        Obx(
          () => isLoading.value
              ? Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}