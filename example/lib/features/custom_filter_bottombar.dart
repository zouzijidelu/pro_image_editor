// import 'package:flutter/material.dart';
// import 'package:pro_image_editor/pro_image_editor.dart';
//
// class CustomFilterBottomBar extends StatelessWidget {
//   final FilterEditorState state;
//
//   const CustomFilterBottomBar({super.key, required this.state});
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // 1. Slider区域
//         _buildSliderArea(state.filterOpacity, context),
//
//         // 2. 滤镜按钮区域
//         _buildFilterButtonsArea(),
//
//         // 3. 操作按钮区域
//         _buildActionButtonsArea(),
//       ],
//     );;
//   }
//
//   Widget _buildSliderArea(double filterOpacity, BuildContext context) {
//     // 计算百分比值：将0-1的范围映射到-100到+100
//     final percentValue = ((filterOpacity * 100) - 50).round();
//     final displayValue = percentValue > 0 ? '+$percentValue' : '$percentValue';
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.black,
//       child: Row(
//         children: [
//           // 左侧百分比显示
//           SizedBox(
//             width: 40,
//             child: Text(
//               displayValue,
//               style: const TextStyle(color: Colors.white, fontSize: 14),
//             ),
//           ),
//
//           // Slider控件
//           Expanded(
//             child: Slider(
//               value: filterOpacity,
//               min: 0,
//               max: 1,
//               divisions: 100,
//               onChanged: (value) {
//                 state.setFilterOpacity(value);
//                 state.filterEditorCallbacks?.handleFilterFactorChange(value);
//               },
//               onChangeEnd: (value) {
//                 state.filterEditorCallbacks?.handleFilterFactorChangeEnd(value);
//               },
//               activeColor: Colors.white,
//               inactiveColor: Colors.grey[800],
//             ),
//           ),
//
//           // 重置按钮
//           TextButton(
//             onPressed: () {
//               state.setFilterOpacity(0.5); // 重置为50%
//               state.filterEditorCallbacks?.handleFilterFactorChangeEnd(0.5);
//             },
//             child: const Text(
//               '重置',
//               style: TextStyle(color: Colors.white, fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterButtonsArea() {
//     final filters = [
//       // 无滤镜选项
//       FilterModel(name: '无', filters: [
//         [
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0,
//           0
//         ]
//       ]),
//
//       // 您提供的三个自定义滤镜
//       FilterModel(
//         name: '明暗',
//         filters: [
//           ColorFilterAddons.colorOverlay(255, 225, 80, 0.08),
//           ColorFilterAddons.saturation(0.1),
//           ColorFilterAddons.contrast(0.05),
//         ],
//       ),
//       FilterModel(
//         name: '鲜明',
//         filters: [
//           ColorFilterAddons.grayscale(),
//           ColorFilterAddons.colorOverlay(100, 28, 210, 0.03),
//           ColorFilterAddons.brightness(1),
//         ],
//       ),
//       FilterModel(
//         name: '变红',
//         filters: [
//           ColorFilterAddons.addictiveColor(255, 0, 0),
//         ],
//       ),
//     ];
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       color: Colors.black,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: filters.map((filter) {
//           final isSelected = filter == state.selectedFilter;
//
//           return GestureDetector(
//             onTap: () => state.setFilter(filter),
//             child: Container(
//               decoration: isSelected
//                   ? BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.white, width: 2),
//               )
//                   : null,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Text(
//                 filter.name,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Colors.grey,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildActionButtonsArea() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//       color: Colors.black,
//       child: Row(
//         children: [
//           // 取消按钮
//           Expanded(
//             child: OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.grey[800],
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               onPressed: state.close,
//               child: const Text('取消'),
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           // 保存按钮
//           Expanded(
//             child: FilledButton(
//               style: FilledButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.blue,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               onPressed: state.done,
//               child: const Text('保存'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class CustomFilterBottomBar extends StatelessWidget {
  final FilterEditorState state;

  const CustomFilterBottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Slider区域
        _buildSliderArea(state.filterOpacity, context),

        // 2. 滤镜按钮区域
        _buildFilterButtonsArea(),

        // 3. 操作按钮区域
        _buildActionButtonsArea(),
      ],
    );;
  }

  Widget _buildSliderArea(double filterOpacity, BuildContext context) {
    // 计算百分比值：将0-1的范围映射到-100到+100
    final percentValue = ((filterOpacity * 100) - 50).round();
    final displayValue = percentValue > 0 ? '+$percentValue' : '$percentValue';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          // 左侧百分比显示
          SizedBox(
            width: 40,
            child: Text(
              displayValue,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // Slider控件
          Expanded(
            child: Slider(
              value: filterOpacity,
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (value) {
                state.setFilterOpacity(value);
                state.filterEditorCallbacks?.handleFilterFactorChange(value);
              },
              onChangeEnd: (value) {
                state.filterEditorCallbacks?.handleFilterFactorChangeEnd(value);
              },
              activeColor: Colors.white,
              inactiveColor: Colors.grey[800],
            ),
          ),

          // 重置按钮
          TextButton(
            onPressed: () {
              state.setFilterOpacity(0.5); // 重置为50%
              state.filterEditorCallbacks?.handleFilterFactorChangeEnd(0.5);
            },
            child: const Text(
              '重置',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtonsArea() {
    final filters = [
      // 无滤镜选项
      FilterModel(name: '无', filters: [
        [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ]
      ]),

      // 您提供的三个自定义滤镜
      FilterModel(
        name: '明暗',
        filters: [
          ColorFilterAddons.colorOverlay(255, 225, 80, 0.08),
          ColorFilterAddons.saturation(0.1),
          ColorFilterAddons.contrast(0.05),
        ],
      ),
      FilterModel(
        name: '鲜明',
        filters: [
          ColorFilterAddons.grayscale(),
          ColorFilterAddons.colorOverlay(100, 28, 210, 0.03),
          ColorFilterAddons.brightness(1),
        ],
      ),
      FilterModel(
        name: '变红',
        filters: [
          ColorFilterAddons.addictiveColor(255, 0, 0),
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final isSelected = filter == state.selectedFilter;

          return GestureDetector(
              onTap: () {
                state.setFilter(filter);
                // state.setStateFilterList(() {});
                // state.filterEditorCallbacks?.handleFilterChanged(filter);
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  state.takeScreenshot();
                });
              },
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                filter.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtonsArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.black,
      child: Row(
        children: [
          // 取消按钮
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: state.close,
              child: const Text('取消'),
            ),
          ),

          const SizedBox(width: 16),

          // 保存按钮
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: state.done,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}