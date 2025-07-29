// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_app_demolab/image_util.dart';
// import 'package:flutter_app_demolab/path_util.dart';
import 'dart:ui' as ui;

// import 'package:flutter_app_demolab/tools/utils/color_util.dart';
// import 'package:flutter_app_demolab/tools/utils/time_util.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCameraPage extends StatefulWidget {
  const MyCameraPage({
    super.key,
    required this.cameras,
    required this.onSelectedImagePathPressed,
  });

  final List<CameraDescription> cameras;
  final Function(String? selectedImagePath) onSelectedImagePathPressed;

  @override
  State<MyCameraPage> createState() => _MyCameraPageState();
}

class _MyCameraPageState extends State<MyCameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  GlobalKey _cameraViewGlobalKey = GlobalKey();
  GlobalKey _cameraContainerGlobalKey = GlobalKey();

  bool enableAudio = false;

  // Counting pointers (number of user fingers on screen)
  ///以下是关于手指缩放画面的变量
  int _pointers = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  Size? mediaSize;
  double? scale;
  double? defaultZoomLevel;

  bool isHasTakePhoto = false;
  bool isCameraFront = true;
  String? selectedImagePath;
  bool isTaking = false;
  bool isCameraStarting = false;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    if (widget.cameras.isNotEmpty && widget.cameras.length >= 2) {
      controller = CameraController(
        // Get a specific camera from the list of available cameras.
        widget.cameras[1],
        // Define the resolution to use.
        ResolutionPreset.high,
      );

      // Next, initialize the controller. This returns a Future.
      setState(() {
        isCameraStarting = true;
      });
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          isCameraStarting = false;
        });
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
            // Handle access errors here.
              break;
            default:
            // Handle other errors here.
              break;
          }
        }
      });
    }

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: buildCameraContainer(context),
    );
  }

  Widget buildCameraContainer(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (widget.cameras.isEmpty) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Text(
          "未获取到可用的相机，请退出重试。",
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      );
    } else {
      return Container(
        key: _cameraContainerGlobalKey,
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Expanded(
                  child: buildFutureBuilder(context),
                )
              ],
            ),
            buildStackBarWidget(context),
          ],
        ),
      );
    }
  }

  Widget buildFutureBuilder(BuildContext context) {
    if (controller != null && controller!.value.isInitialized) {
      ///初始化完成以后，再获取可以缩放画面最大最小的参数
      mediaSize = MediaQuery.of(context).size;
      scale = 1 / (controller!.value.aspectRatio * mediaSize!.aspectRatio);
      controller!
          .getMaxZoomLevel()
          .then((double value) => _maxAvailableZoom = value);
      controller!
          .getMinZoomLevel()
          .then((double value) => _minAvailableZoom = value);
      return buildCameraPreviewWidget(context);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget buildStackBarWidget(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    double bottomBarHeight = 120;
    double cameraHeight = size.height - bottomBarHeight;
    EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    return Container(
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size.width,
              height: bottomBarHeight,
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 25,
                    child: buildCloseIcon(context),
                  ),
                  buildTakePhotoButton(context),
                  Positioned(
                    right: 25,
                    child: buildRetakeButton(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: viewPadding.top + 25,
            right: 10,
            child: buildExchangeButton(context),
          ),
        ],
      ),
    );
  }

  Widget buildCameraPreviewWidget(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final CameraController? cameraController = controller;

    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          RepaintBoundary(
            key: _cameraViewGlobalKey,
            child: Transform.scale(
              scale: 1.0,
              // scale: controller!.value.aspectRatio / deviceRatio,
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: size.aspectRatio,
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: SizedBox(
                      width: size.width,
                      height: size.width * cameraController!.value.aspectRatio,
                      child: Stack(fit: StackFit.expand, children: <Widget>[
                        _cameraPreviewWidget(),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'cameraController未初始化完成',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onTapDown: (TapDownDetails details) =>
                      onViewFinderTap(details, constraints),
                );
              }),
        ),
      );
    }
  }

  Widget buildCloseIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.transparent,
              style: BorderStyle.solid,
              width: 1,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Icon(
            Icons.close,
            size: 30,
            color: Colors.white,
            weight: 0.5,
          ),
        ),
      ),
    );
  }

  Widget buildTakePhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isTaking == false) {
          if (isHasTakePhoto == true) {
            widget.onSelectedImagePathPressed(selectedImagePath);
            Navigator.pop(context);
          } else {
            onTakePicturePressed();
          }
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Image.asset(
              //   "assets/camera/my_take_photo.png",
              //   width: 60.0,
              //   height: 60.0,
              //   fit: BoxFit.contain,
              // ),
              const Icon(Icons.camera_alt),
              buildHasCheck(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHasCheck(BuildContext context) {
    if (isTaking == true) {
      return buildLoading(context);
    }
    if (isHasTakePhoto) {
      return Icon(
        Icons.check,
        size: 30,
        color: Colors.black,
        weight: 0.5,
      );
    }
    return Container();
  }

  Widget buildExchangeButton(BuildContext context) {
    if (isHasTakePhoto == true) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        onExchangeCameraPressed();
      },
      child: Container(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.transparent,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.transparent,
                style: BorderStyle.solid,
                width: 5,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child:
            // Image.asset(
            //   "assets/camera/my_exchange_camera.png",
            //   width: 50.0,
            //   height: 50.0,
            //   fit: BoxFit.contain,
            // ),
            const Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }

  Widget buildRetakeButton(BuildContext context) {
    if (isHasTakePhoto == false) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        onRetakeButtonPressed();
      },
      child: Container(
        color: Colors.transparent,
        child: Container(
          width: 70,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,//.hexColor(0x000000, alpha: 0.25),
            border: Border.all(
              color: Colors.transparent,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Text(
            "重拍",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoading(BuildContext context) {
    return SizedBox(
      height: 58,
      width: 58,
      child: CircularProgressIndicator(
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation(Colors.blue),
      ),
    );
  }

  void onRetakeButtonPressed() {
    setState(() {
      isHasTakePhoto = false;
    });
    selectedImagePath = null;
    onResumePreview();
  }

  Future<void> onPausePreview() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      print('Error: select a camera first.');
      return;
    }

    if (!cameraController.value.isPreviewPaused) {
      await cameraController.pausePreview();
    }
  }

  Future<void> onResumePreview() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      print('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isPreviewPaused) {
      await cameraController.resumePreview();
    }
  }

  Future<void> onExchangeCameraPressed() async {
    setState(() {
      isHasTakePhoto = false;
    });
    if (isCameraFront == true) {
      if (widget.cameras.isNotEmpty && widget.cameras.length >= 2) {
        onNewCameraSelected(widget.cameras[0]);
      }
      isCameraFront = false;
    } else {
      if (widget.cameras.isNotEmpty && widget.cameras.length >= 2) {
        onNewCameraSelected(widget.cameras[1]);
      }
      isCameraFront = true;
    }
  }

  void onTakePicturePressed() {
    onTakePicture();
  }

  Future<void> onTakePicture() async {
    setState(() {
      isTaking = true;
    });

    takePicture().then((XFile? file) async {
      // if (mounted) {
      //   onPausePreview();
      //   if (file != null) {
      //     // 保存到相册
      //     // await SaveToAlbumUtil.saveLocalImage(file.path);
      //     RenderBox renderBox = _cameraContainerGlobalKey.currentContext!
      //         .findRenderObject() as RenderBox;
      //     // offset.dx , offset.dy 就是控件的左上角坐标
      //     Offset offset = renderBox.localToGlobal(Offset.zero);
      //     //获取size
      //     Size size = renderBox.size;
      //
      //     // 创建文件path
      //     String imageDir = await PathUtil.createDirectory("local_images");
      //     String imagePath = '$imageDir/${TimeUtil.currentTimeMillis()}.png';
      //
      //     // // 获取当前设备的像素比
      //     double dpr = ui.window.devicePixelRatio;
      //     print("devicePixelRatio:${dpr}");
      //     print(
      //         "offset:(${offset.dx},${offset.dy})--size:(${size.width},${size.height})");
      //
      //     File? targetFile = await ImageUtil.cropImage(
      //       file.path,
      //       imagePath,
      //       x: (dpr * offset.dx).floor(),
      //       y: (dpr * offset.dy).floor(),
      //       width: (dpr * size.width).ceil(),
      //       height: (dpr * size.height).ceil(),
      //       flipHorizontal: isCameraFront,
      //     );
      //     print("cropImage targetFile:${targetFile}");
      //     if (targetFile != null) {
      //       selectedImagePath = targetFile.path;
      //       // await SaveToAlbumUtil.saveLocalImage(targetFile.path);
      //     }
      //     setState(() {
      //       isHasTakePhoto = true;
      //     });
      //   } else {
      //     // 没有获得图片，重试
      //   }
      //   setState(() {
      //     isTaking = false;
      //   });
      // }
    });
  }

  Future<void> _handleScaleStart(ScaleStartDetails details) async {
    _baseScale = _currentScale;
    await controller!.setZoomLevel(_minAvailableZoom);
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController? cameraController = controller;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController?.setExposurePoint(offset);
    cameraController?.setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        print("Camera error ${cameraController.value.errorDescription}");
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object>>[
        // The exposure mode is currently not supported on the web.
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      // _showCameraException(e);
    }

    setState(() {
      isCameraStarting = true;
    });
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isCameraStarting = false;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
          // Handle access errors here.
            break;
          default:
          // Handle other errors here.
            break;
        }
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      print("Error: select a camera first.");
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print("takePicture CameraException e:${e.toString()}");
      return null;
    }
  }
}

