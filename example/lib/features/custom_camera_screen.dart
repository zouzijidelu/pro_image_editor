import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = true;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available')),
        );
        Navigator.pop(context);
        return;
      }

      // 直接使用高质量分辨率预设
      _controller = CameraController(
        cameras[_isFrontCamera ? 1 : 0],
        ResolutionPreset.high, // 使用最高质量预设
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      setState(() => _isLoading = true);

      // 简化初始化流程
      _initializeControllerFuture = _controller.initialize().then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    } catch (e) {
      print("Camera initialization failed: $e");
      Navigator.pop(context);
    }
  }

  Future<XFile?> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final originalImage = await _controller.takePicture();
      return originalImage;
      // 应用2000x1500分辨率要求
      return await _resizeImageIfNeeded(originalImage);
    } catch (e) {
      print("拍照失败: $e");
      return null;
    }
  }

  /// 将图片调整为2000x1500尺寸
  Future<XFile> _resizeImageIfNeeded(XFile originalImage) async {
    final extDir = await getTemporaryDirectory();
    final dirPath = '${extDir.path}/Pictures';
    await Directory(dirPath).create(recursive: true);

    final targetPath = path_lib.join(
        dirPath,
        '${DateTime.now().millisecondsSinceEpoch}.jpg'
    );

    final originalFile = File(originalImage.path);
    final originalBytes = await originalFile.readAsBytes();

    // 使用image包调整大小
    final decodedImage = img.decodeImage(originalBytes);
    if (decodedImage == null) return originalImage;

    final resizedImage = img.copyResize(
      decodedImage,
      width: 2000,
      height: 1500,
      interpolation: img.Interpolation.linear,
    );

    final resizedBytes = img.encodeJpg(resizedImage, quality: 95);
    await File(targetPath).writeAsBytes(resizedBytes);

    return XFile(targetPath);
  }

  void _toggleCamera() {
    setState(() => _isFrontCamera = !_isFrontCamera);
    _initializeCamera();
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_controller.value.isInitialized)
            CameraPreview(_controller),

          // UI覆盖层
          _buildCameraOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Stack(
      children: [
        // 顶部栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // 中间参考线
        const Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SpaceLabel(label: "天花板", number: 1),
                  SizedBox(height: 20),
                  _SpaceLabel(label: "墙壁", number: 2),
                  SizedBox(height: 20),
                  _SpaceLabel(label: "地面", number: 3),
                ],
              ),
            ),
          ),
        ),

        // 底部操作栏
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // 拍照按钮
              _CameraButton(
                onPressed: () async {
                  final image = await _takePicture();
                  if (image != null && mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              const SizedBox(height: 20),

              // 相机切换按钮
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                onPressed: _toggleCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: IconButton(
        icon: const Icon(Icons.camera, size: 50, color: Colors.white),
        padding: const EdgeInsets.all(15),
        onPressed: onPressed,
      ),
    );
  }
}

class _SpaceLabel extends StatelessWidget {
  final String label;
  final int number;

  const _SpaceLabel({
    required this.label,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label$number",
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}