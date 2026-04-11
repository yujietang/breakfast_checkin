import 'package:flutter/material.dart';
import '../models/stone_level.dart';
import '../models/user_data.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';

/// 皮肤库页面 - 纯展示和切换（免费版）
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final UserDataService _userService = UserDataService();
  bool _isLoading = true;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _userService.loadUserData();
    setState(() {
      _userData = _userService.userData;
      _isLoading = false;
    });
  }

  Future<void> _switchSkin(String skinId) async {
    await _userService.switchSkin(skinId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('皮肤已切换')),
      );
    }
  }

  String _getUnlockCondition(String skinId) {
    final conditions = {
      'default': '默认拥有',
      'gold': '连续打卡7天解锁',
      'crystal': '累计打卡30天解锁',
      'rainbow': '累计打卡50天解锁',
      'blackhole': '邀请1位好友解锁',
    };
    return conditions[skinId] ?? '特殊活动解锁';
  }

  bool _isSkinUnlocked(String skinId, UserData userData) {
    return userData.purchasedSkins.contains(skinId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userData = _userData!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('皮肤库'),
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: StoneSkin.allSkins.length,
        itemBuilder: (context, index) {
          final skin = StoneSkin.allSkins[index];
          final isUnlocked = _isSkinUnlocked(skin.id, userData);
          final isSelected = userData.currentSkin == skin.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected
                  ? const BorderSide(color: AppColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 皮肤预览
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.primary.withAlpha(20)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.style,
                        size: 40,
                        color: isUnlocked ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 皮肤信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skin.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skin.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnlocked
                                ? AppColors.textSecondary
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? AppColors.success.withAlpha(30)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isUnlocked ? '已解锁' : _getUnlockCondition(skin.id),
                            style: TextStyle(
                              color: isUnlocked
                                  ? AppColors.success
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  if (isUnlocked)
                    ElevatedButton(
                      onPressed: isSelected ? null : () => _switchSkin(skin.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.grey[300] : AppColors.primary,
                        foregroundColor:
                            isSelected ? Colors.grey[600] : Colors.white,
                      ),
                      child: Text(isSelected ? '使用中' : '使用'),
                    )
                  else
                    const Icon(
                      Icons.lock,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
