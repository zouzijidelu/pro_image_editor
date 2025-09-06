import 'package:flutter/material.dart';

import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/designs/grounded/grounded_design.dart';
import '/pro_image_editor.dart';

/// A widget that represents a grounded tune adjustment bar for the editor.
///
/// The `GroundedTuneBar` is used to display and manage tune adjustment options
/// for the image editor, providing the ability to adjust various parameters
/// such as brightness, contrast, and saturation.
///
/// This widget interacts with the `TuneEditorState` to apply the changes and
/// uses the provided `configs` and `callbacks` for customization and response
/// handling.
class GroundedTuneBar extends StatefulWidget with SimpleConfigsAccess {
  /// Creates a `GroundedTuneBar` with the given configurations and callbacks.
  ///
  /// The [configs] parameter provides the configuration settings for the
  /// editor.
  /// The [callbacks] parameter provides the callback functions for handling
  /// user interactions.
  /// The [editor] parameter refers to the `TuneEditorState` that manages the
  /// image editing state.
  const GroundedTuneBar({
    super.key,
    required this.configs,
    required this.callbacks,
    required this.editor,
  });

  /// The editor state that holds filter and editing information.
  final TuneEditorState editor;

  @override
  final ProImageEditorConfigs configs;

  @override
  final ProImageEditorCallbacks callbacks;

  @override
  State<GroundedTuneBar> createState() => _GroundedTuneBarState();
}

class _GroundedTuneBarState extends State<GroundedTuneBar>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  /// Controller for managing the scroll of the horizontal filter list.
  late final ScrollController _bottomBarScrollCtrl;
  /// 控制参数详情区域的显示/隐藏状态
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _bottomBarScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _bottomBarScrollCtrl.dispose();
    super.dispose();
  }

  TuneEditorState get tuneEditor => widget.editor;

  @override
  Widget build(BuildContext context) {
    return GroundedBottomWrapper(
      theme: configs.theme,
      children: (constraints) => [
        _buildFunctions(constraints),
        GroundedBottomBar(
          configs: configs,
          done: widget.editor.done,
          close: widget.editor.close,
          undo: tuneEditor.undo,
          redo: tuneEditor.redo,
          enableRedo: tuneEditor.canRedo,
          enableUndo: tuneEditor.canUndo,
        ),
      ],
    );
  }

  Widget _buildFunctions1(BoxConstraints constraints) {
    var bottomTextStyle = const TextStyle(fontSize: 10.0, color: Colors.white);
    double bottomIconSize = 22.0;
    return Container(
      color: mainEditorConfigs.style.bottomBarBackground,
      width: double.infinity,
      child: FadeInUp(
        duration: kGroundedFadeInDuration,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RepaintBoundary(
                child: StreamBuilder(
                    stream: tuneEditor.uiStream.stream,
                    builder: (context, snapshot) {
                      var activeOption = tuneEditor
                          .tuneAdjustmentList[tuneEditor.selectedIndex];
                      var activeMatrix = tuneEditor
                          .tuneAdjustmentMatrix[tuneEditor.selectedIndex];
                      return SizedBox(
                        height: 40,
                        child: Slider(
                          min: activeOption.min,
                          max: activeOption.max,
                          divisions: activeOption.divisions,
                          label: (activeMatrix.value *
                                  activeOption.labelMultiplier)
                              .round()
                              .toString(),
                          value: activeMatrix.value,
                          onChangeStart: tuneEditor.onChangedStart,
                          onChanged: tuneEditor.onChanged,
                          onChangeEnd: tuneEditor.onChangedEnd,
                        ),
                      );
                    }),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: Scrollbar(
                controller: tuneEditor.bottomBarScrollCtrl,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                thickness: isDesktop ? null : 0,
                child: SingleChildScrollView(
                  controller: tuneEditor.bottomBarScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          tuneEditor.tuneAdjustmentMatrix.length, (index) {
                        var item = tuneEditor.tuneAdjustmentList[index];
                        return FlatIconTextButton(
                          label: Text(item.label, style: bottomTextStyle),
                          icon: Icon(
                            item.icon,
                            size: bottomIconSize,
                            color: tuneEditor.selectedIndex == index
                                ? kImageEditorPrimaryColor
                                : Colors.white,
                          ),
                          onPressed: () {
                            tuneEditor.setState(() {
                              tuneEditor.selectedIndex = index;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFunctions(BoxConstraints constraints) {
    var bottomTextStyle = const TextStyle(fontSize: 10.0, color: Colors.white);
    double bottomIconSize = 22.0;

    // 定义三个预设模板
    final Map<String, Map<String, double>> templates = {
      '明亮': {'brightness': 0.2, 'contrast': 0.1, 'saturation': 0.1},
      '淡化': {'brightness': 0.0, 'contrast': -0.1, 'saturation': 0.0},
      '对比': {'brightness': 0.0, 'contrast': 0.3, 'saturation': 0.1},
    };

    return Container(
      color: mainEditorConfigs.style.bottomBarBackground,
      width: double.infinity,
      child: FadeInUp(
        duration: kGroundedFadeInDuration,
        child: Column(
          children: [
            // 垂直排列的滑块区域
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RepaintBoundary(
                child: StreamBuilder(
                  stream: tuneEditor.uiStream.stream,
                  builder: (context, snapshot) {
                    return SizedBox(
                      height: 180,
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // 亮度滑块
                          _buildSlider(
                            label: 'brightness',
                            index: _findAdjustmentIndex('brightness'),
                            textStyle: bottomTextStyle,
                          ),
                          // 对比度滑块
                          _buildSlider(
                            label: 'contrast',
                            index: _findAdjustmentIndex('contrast'),
                            textStyle: bottomTextStyle,
                          ),
                          // 饱和度滑块
                          _buildSlider(
                            label: 'saturation',
                            index: _findAdjustmentIndex('saturation'),
                            textStyle: bottomTextStyle,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 模板按钮区域
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: templates.entries.map((template) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF444444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    onPressed: () {
                      _applyTemplate(template.key, template.value);
                    },
                    child: Text(template.key),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

// 辅助方法：查找调整项的索引
  int _findAdjustmentIndex(String id) {
    return tuneEditor.tuneAdjustmentList.indexWhere((item) => item.id == id);
  }

// 辅助方法：构建单个滑块
  Widget _buildSlider({
    required String label,
    required int index,
    required TextStyle textStyle,
  }) {
    if (index < 0) return const SizedBox(); // 如果找不到对应调整项，返回空组件

    var item = tuneEditor.tuneAdjustmentList[index];
    var matrix = tuneEditor.tuneAdjustmentMatrix[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              item.label,
              style: textStyle,
            ),
          ),
          Expanded(
            child: Slider(
              min: item.min,
              max: item.max,
              divisions: item.divisions,
              value: matrix.value,
              onChanged: (value) {
                // 为每个滑块创建独立的回调函数
                _onSliderChanged(index, value);
              },
              onChangeStart: (value) {
                _onSliderChangeStart(index, value);
              },
              onChangeEnd: (value) {
                _onSliderChangeEnd(index, value);
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(matrix.value * item.labelMultiplier).round()}',
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

// 独立的滑块变更处理方法
  void _onSliderChangeStart(int index, double value) {
    // 保存当前状态到撤销栈
    tuneEditor.onChangedStart(value);
  }

  void _onSliderChanged(int index, double value) {
    // 获取对应的调整项
    var selectedItem = tuneEditor.tuneAdjustmentList[index];

    // 更新对应的调整矩阵
    tuneEditor.tuneAdjustmentMatrix[index] = TuneAdjustmentMatrix(
      id: selectedItem.id,
      value: value,
      matrix: selectedItem.toMatrix(value),
    );

    // 触发UI更新
    tuneEditor.tuneAdjustmentMatrix = [...tuneEditor.tuneAdjustmentMatrix];
    tuneEditor.uiStream.add(null);
    tuneEditor.tuneEditorCallbacks?.handleTuneFactorChange(tuneEditor.tuneAdjustmentMatrix);
  }

  void _onSliderChangeEnd(int index, double value) {
    setState(() {});
    tuneEditor.tuneEditorCallbacks?.handleTuneFactorChangeEnd(tuneEditor.tuneAdjustmentMatrix);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tuneEditor.takeScreenshot();
    });
  }

  void _applyTemplate(String templateName, Map<String, double> templateValues) {
    // 保存当前状态到撤销栈
    tuneEditor.onChangedStart(0);

    // 应用模板值到各个调整项
    for (var entry in templateValues.entries) {
      String adjustmentId = entry.key;
      double value = entry.value;

      // 找到对应的调整项索引
      int index = _findAdjustmentIndex(adjustmentId);

      if (index >= 0) {
        var item = tuneEditor.tuneAdjustmentList[index];

        // 更新调整矩阵
        tuneEditor.tuneAdjustmentMatrix[index] = TuneAdjustmentMatrix(
          id: item.id,
          value: value,
          matrix: item.toMatrix(value),
        );
      }
    }

    // 关键修复：确保矩阵数组引用更新，触发状态变化
    tuneEditor.tuneAdjustmentMatrix = [...tuneEditor.tuneAdjustmentMatrix];

    // 触发UI更新
    setState(() {});
    tuneEditor.uiStream.add(null);

    // 关键修复：调用必要的回调函数
    tuneEditor.tuneEditorCallbacks?.handleTuneFactorChange(tuneEditor.tuneAdjustmentMatrix);

    // 完成更改
    tuneEditor.tuneEditorCallbacks?.handleTuneFactorChangeEnd(tuneEditor.tuneAdjustmentMatrix);

    // 关键修复：触发截图以更新预览
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tuneEditor.takeScreenshot();
    });

    // 用户反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用"$templateName"模板'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
