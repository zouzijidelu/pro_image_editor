import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  File? _rotatedImage; // 存储旋转后的图片
  bool _isLoading = true; // 加载状态

  @override
  void initState() {
    super.initState();
    // 初始化时自动旋转图片
    _rotateImageIfNeeded();
  }

  Future<void> _rotateImageIfNeeded() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();

    try {
      final exifData = await readExifFromBytes(bytes);

      // // 修复1: 使用正确方式获取 EXIF 方向值
      // final IfdTag? orientationTag = exifData['Image Orientation']; // 明确指定类型
      int? orientation = 6;
      //
      // if (orientationTag != null) {
      //   orientation = orientationTag.values.toList().first;
      // }
      //
      // // 修复3: 检查方向值并计算旋转角度
      // if (orientation > 4) {
      final img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        int rotationAngle = 0;
        switch (orientation) {
          case 5: case 6:
          rotationAngle = 270;
          break;
          case 7: case 8:
          rotationAngle = 90;
          break;
          default:
            rotationAngle = 180;
        }

        final rotatedImage = img.copyRotate(capturedImage, angle: rotationAngle);
        final tempDir = await getTemporaryDirectory();
        final rotatedPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(rotatedPath).writeAsBytes(img.encodeJpg(rotatedImage));

        setState(() {
          _rotatedImage = File(rotatedPath);
          _isLoading = false;
        });
        return;
      }
      // }
    } catch (e) {
      print('图片旋转时出错: $e');
    }

    setState(() {
      _rotatedImage = file;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(_rotatedImage!),
    );
  }

  @override
  void dispose() {
    // 清理临时文件
    if (_rotatedImage?.path != widget.imagePath) {
      try {
        _rotatedImage?.delete();
      } catch (e) {
        print('Error deleting rotated image: $e');
      }
    }
    super.dispose();
  }
}