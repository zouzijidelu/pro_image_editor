// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/mixin/example_helper.dart';
import 'camera_example.dart';
import 'camera_example1.dart';
import 'custom_camera_screen.dart';
/// Specifies the source where the picked image should come from.
enum MyImageSource {

  /// Opens up the device camera, letting the user to take a new picture.
  systemCamera,

  customCamera,
  cameraExample,

  /// Opens the user's photo gallery.
  gallery,
}

/// The example how to pick images from the gallery or with the camera.
class PickImageExample extends StatefulWidget {
  /// Creates a new [PickImageExample] widget.
  const PickImageExample({super.key});

  @override
  State<PickImageExample> createState() => _PickImageExampleState();
}

class _PickImageExampleState extends State<PickImageExample>
    with ExampleHelperState<PickImageExample> {
  final bool _cameraIsSupported =
      kIsWeb || (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS);

  late final _callbacks = ProImageEditorCallbacks(
    onImageEditingStarted: onImageEditingStarted,
    onImageEditingComplete: onImageEditingComplete,
    onCloseEditor: (editorMode) => onCloseEditor(editorMode: editorMode),
    mainEditorCallbacks: MainEditorCallbacks(
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
    ),
  );
  final _configs = ProImageEditorConfigs(
    designMode: platformDesignMode,
  );

  void _openPicker(MyImageSource source) async {
    if (source == MyImageSource.customCamera) {
      // 使用自定义相机而不是ImagePicker
      final XFile? image = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomCameraScreen(),
        ),
      );

      if (image != null) {
        _openEditor(image);
      }
    } else if (source == MyImageSource.cameraExample) {
      final cameras = await availableCameras();

      // Get a specific camera from the list of available cameras.
      final firstCamera = cameras.first;
      final XFile? image = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(camera: firstCamera,),
        ),
      );
      if (image != null) {
        _openEditor(image);
      }
    } else {
      ImageSource s = source == MyImageSource.gallery ? ImageSource.gallery : ImageSource.camera;

      // 保持原有的相册功能
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: s);

      if (image != null) {
        _openEditor(image);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick from gallery or camera'),
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: _cameraIsSupported
                ? () => _openPicker(MyImageSource.systemCamera)
                : null,
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('打开系统相机'),
            subtitle: _cameraIsSupported
                ? null
                : const Text('The camera is not supported on this platform.'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            onTap: _cameraIsSupported
                ? () => _openPicker(MyImageSource.customCamera)
                : null,
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('打开自定义相机'),
            subtitle: _cameraIsSupported
                ? null
                : const Text('The camera is not supported on this platform.'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            onTap: _cameraIsSupported
                ? () => _openPicker(MyImageSource.cameraExample)
                : null,
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('相机示例'),
            subtitle: _cameraIsSupported
                ? null
                : const Text('The camera is not supported on this platform.'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            onTap: () => _openPicker(MyImageSource.gallery),
            leading: const Icon(Icons.image_outlined),
            title: const Text('Open from gallery'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openEditor(XFile image) async {
    String? path;
    Uint8List? bytes;

    if (kIsWeb) {
      bytes = await image.readAsBytes();
      if (!mounted) return;
      await precacheImage(MemoryImage(bytes), context);
    } else {
      path = image.path;
      if (!mounted) return;
      await precacheImage(FileImage(File(path)), context);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildEditor(path: path, bytes: bytes),
      ),
    );
  }

  Widget _buildEditor({String? path, Uint8List? bytes}) {
    if (path != null) {
      return ProImageEditor.file(
        File(path),
        callbacks: _callbacks,
        configs: _configs,
      );
    } else {
      return ProImageEditor.memory(
        bytes!,
        callbacks: _callbacks,
        configs: _configs,
      );
    }
  }
}
