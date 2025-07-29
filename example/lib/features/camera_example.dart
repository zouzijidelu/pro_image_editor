import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

// 自定义设备方向枚举
enum MYDeviceOrientation {
  portrait,
  landscapeLeft,
  landscapeRight,
  faceUp,
  faceDown,
  unknown
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Size? _previewSize;
  double? _aspectRatio;

  // 缩放相关变量
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  // 缩放速度控制
  final double _zoomSensitivity = 1.0;

  // 曝光度相关变量
  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _exposureOffset = 0.0;

  // 使用自定义的物理方向枚举
  MYDeviceOrientation _myDeviceOrientation = MYDeviceOrientation.unknown;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // 添加设备方向监听
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 启动物理方向监听
    _startPhysicalOrientationListener();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
    );

    _initializeControllerFuture = _controller.initialize().then((_) async {
      if (!mounted) return;

      // 先解锁方向，然后重新设置方向
      await _controller.unlockCaptureOrientation();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _minZoom = await _controller.getMinZoomLevel();
      _maxZoom = await _controller.getMaxZoomLevel();

      // 修复：正确获取曝光值范围
      _minExposureOffset = await _controller.getMinExposureOffset();
      _maxExposureOffset = await _controller.getMaxExposureOffset();
      _exposureOffset = await _controller.getExposureOffsetStepSize();

      setState(() {
        _previewSize = _controller.value.previewSize;
        if (_previewSize != null) {
          _aspectRatio = _previewSize!.height / _previewSize!.width;
        }
      });
    });
  }

  // 启动物理方向监听
  void _startPhysicalOrientationListener() {
    // 添加低通滤波器以减少噪音
    const double filterFactor = 0.2;
    List<double> lastValues = [0, 0, 0];

    _accelerometerSubscription?.cancel();

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      // 应用低通滤波器
      double x = lastValues[0] * (1 - filterFactor) + event.x * filterFactor;
      double y = lastValues[1] * (1 - filterFactor) + event.y * filterFactor;
      double z = lastValues[2] * (1 - filterFactor) + event.z * filterFactor;

      lastValues = [x, y, z];

      // 计算物理方向
      final newOrientation = _calculatePhysicalOrientation(x, y, z);

      // 只在方向变化时更新UI
      if (newOrientation != _myDeviceOrientation && mounted) {
        setState(() {
          _myDeviceOrientation = newOrientation;
        });
      }
    });
  }

  // 根据加速度数据计算物理方向
  MYDeviceOrientation _calculatePhysicalOrientation(double x, double y, double z) {
    const double forceThreshold = 1.0;
    const double verticalThreshold = 0.75;

    // 计算绝对值和
    double absSum = x.abs() + y.abs() + z.abs();

    // 计算每个轴的重力分量比例
    double xRatio = (x / 9.8).abs();
    double yRatio = (y / 9.8).abs();
    double zRatio = (z / 9.8).abs();

    // 1. 检查设备是否平放
    if (zRatio > verticalThreshold) {
      return z > 0 ? MYDeviceOrientation.faceDown : MYDeviceOrientation.faceUp;
    }

    // 2. 检查设备是否竖屏
    if (yRatio > verticalThreshold && yRatio > xRatio) {
      return MYDeviceOrientation.portrait;
    }

    // 3. 检查设备是否横屏
    if (xRatio > verticalThreshold && xRatio > yRatio) {
      return x > 0 ? MYDeviceOrientation.landscapeLeft : MYDeviceOrientation.landscapeRight;
    }

    return MYDeviceOrientation.unknown;
  }

  // 设置曝光度
  Future<void> _setExposureOffset(double value) async {
    if (!_controller.value.isInitialized) return;

    try {
      await _controller.setExposureOffset(value);
      setState(() {
        _exposureOffset = value;
      });
    } catch (e) {
      print("设置曝光度失败: $e");
    }
  }

  // 增加曝光值
  void _increaseExposure() {
    double newValue = _exposureOffset + 0.2;
    newValue = newValue.clamp(_minExposureOffset, _maxExposureOffset);
    _setExposureOffset(newValue);
  }

  // 减少曝光值
  void _decreaseExposure() {
    double newValue = _exposureOffset - 0.2;
    newValue = newValue.clamp(_minExposureOffset, _maxExposureOffset);
    _setExposureOffset(newValue);
  }

  // 曝光度按钮组
  Widget _buildExposureButtons() {
    if (_minExposureOffset >= _maxExposureOffset) {
      return const SizedBox.shrink(); // 设备不支持曝光调节时隐藏
    }

    return Positioned(
      left: 20,
      bottom: MediaQuery.of(context).viewPadding.bottom + 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 减号按钮
            FloatingActionButton(
              backgroundColor: Colors.black87,
              mini: true,
              onPressed: _decreaseExposure,
              child: const Icon(Icons.remove, color: Colors.white),
            ),
            const SizedBox(width: 10),
            // 显示当前曝光值
            Text(
              '曝光: ${_exposureOffset.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 10),
            // 加号按钮
            FloatingActionButton(
              backgroundColor: Colors.black87,
              mini: true,
              onPressed: _increaseExposure,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 重置方向首选项
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 取消传感器订阅
    _accelerometerSubscription?.cancel();

    _controller.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_controller.value.isInitialized) return;
    final double scaleChange = details.scale - 1.0;
    double newZoom = _baseZoom + (scaleChange * _zoomSensitivity);
    newZoom = newZoom.clamp(_minZoom, _maxZoom);
    setState(() => _currentZoom = newZoom);
    _controller.setZoomLevel(_currentZoom);
  }

  Widget _buildZoomIndicator() {
    if (_minZoom == _maxZoom) return const SizedBox.shrink();

    return Positioned(
      right: 20,
      top: MediaQuery.of(context).padding.top + 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${_currentZoom.toStringAsFixed(1)}×',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  // 构建方向提示UI - 使用自定义的物理方向
  Widget _buildOrientationIndicator() {
    // 当前是竖屏方向
    if (_myDeviceOrientation == MYDeviceOrientation.portrait) {
      return Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black54,
          child: const Text(
            '请横屏拍摄',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // 当前是横屏方向
    if (_myDeviceOrientation == MYDeviceOrientation.landscapeLeft ||
        _myDeviceOrientation == MYDeviceOrientation.landscapeRight) {
      return Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _myDeviceOrientation == MYDeviceOrientation.landscapeLeft
                  ? '左横屏拍摄' : '右横屏拍摄',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 其他情况不显示指示器
    return const SizedBox.shrink();
  }

  // 曝光控制按钮
  Widget _buildExposureControlButton() {
    if (_minExposureOffset >= _maxExposureOffset) {
      return const SizedBox.shrink(); // 设备不支持曝光调节时隐藏
    }

    return Positioned(
      left: 20,
      bottom: MediaQuery.of(context).viewPadding.bottom + 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.exposure_minus_1, color: Colors.white),
              onPressed: _decreaseExposure,
            ),
            const SizedBox(width: 5),
            Text(
              '曝光',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.exposure_plus_1, color: Colors.white),
              onPressed: _increaseExposure,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
        actions: [
          if (_previewSize != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_previewSize!.width.toInt()}×${_previewSize!.height.toInt()}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // 相机预览 + 手势识别
                GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),

                // 添加缩放指示器
                _buildZoomIndicator(),

                // 添加方向指示器
                _buildOrientationIndicator(),

                // 添加曝光按钮组
                _buildExposureControlButton(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            // 检查当前物理方向
            if (_myDeviceOrientation != MYDeviceOrientation.landscapeLeft &&
                _myDeviceOrientation != MYDeviceOrientation.landscapeRight) {
              // 非横屏状态下提示用户
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请横屏拍摄以获得最佳效果'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // 横屏状态下拍照
            final image = await _controller.takePicture();
            // if (!context.mounted) return;
            //
            // // 根据物理方向决定旋转角度
            // int rotationAngle = 0;
            // if (_myDeviceOrientation == MYDeviceOrientation.landscapeLeft) {
            //   rotationAngle = 270; // 左横屏旋转270度
            // } else if (_myDeviceOrientation == MYDeviceOrientation.landscapeRight) {
            //   rotationAngle = 90; // 右横屏旋转90度
            // }

            // final rotatedImage = await rotateImage(image, degrees: rotationAngle);
            Navigator.pop(context, image);
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  // 核心旋转函数
  Future<XFile> rotateImage(
      XFile originalFile, {
        required int degrees, // 旋转角度 (90, 180, 270)
      }) async {
    final Uint8List bytes = await originalFile.readAsBytes();
    final img.Image originalImage = img.decodeImage(bytes)!;

    // 执行旋转
    final img.Image rotatedImage = img.copyRotate(originalImage, angle: degrees);

    final List<int> newImageBytes = img.encodeJpg(rotatedImage);

    final Directory tempDir = await getTemporaryDirectory();
    final String newPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newFile = File(newPath);

    await newFile.writeAsBytes(newImageBytes);
    return XFile(newFile.path);
  }
}