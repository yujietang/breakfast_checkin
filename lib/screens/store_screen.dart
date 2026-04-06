import 'package:flutter/material.dart';
import '../models/stone_level.dart';
import '../models/user_data.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';

/// 商店页面 - 皮肤购买
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

  Future<void> _purchaseSkin(StoneSkin skin) async {
    if (skin.price == 0) return;

    // 显示购买确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('购买皮肤'),
        content: Text('确定要购买"${skin.name}"吗？\n价格: ¥${skin.price.toStringAsFixed(0)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认购买'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 调用实际支付接口
      final success = await _userService.purchaseSkin(skin.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功购买 ${skin.name}!')),
        );
        await _loadData();
      }
    }
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

  Future<void> _upgradePremium() async {
    // 显示订阅选项
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('升级会员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '解锁全部功能',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPremiumOption('月度会员', '¥9.9/月', '按月订阅，随时取消'),
            const SizedBox(height: 8),
            _buildPremiumOption('年度会员', '¥99/年', '省¥19.8，推荐！'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: 调用实际支付接口
      final expiry = result.contains('年')
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));
      await _userService.upgradePremium(expiry);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('升级成功！')),
        );
      }
    }
  }

  Widget _buildPremiumOption(String title, String price, String desc) {
    return ListTile(
      tileColor: AppColors.primary.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withAlpha(50)),
      ),
      title: Text(title),
      subtitle: Text(desc),
      trailing: Text(
        price,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: 16,
        ),
      ),
      onTap: () => Navigator.pop(context, title),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userData = _userData!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('商店'),
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 会员状态卡片
            _buildMembershipCard(userData),
            const SizedBox(height: 24),
            
            // 皮肤列表
            const Text(
              '胆囊皮肤',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '购买后可永久使用',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...StoneSkin.allSkins.map((skin) => _buildSkinCard(skin, userData)),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(UserData userData) {
    final isPremium = userData.isPremiumValid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? Colors.orange : AppColors.primary).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.diamond : Icons.star,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                isPremium ? '尊贵会员' : '免费用户',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPremium && userData.premiumExpiry != null)
            Text(
              '有效期至: ${_formatDate(userData.premiumExpiry!)}',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBenefitChip('去除广告', isPremium),
              _buildBenefitChip('无限补卡', isPremium),
              _buildBenefitChip('全部皮肤', isPremium),
              _buildBenefitChip('高级统计', isPremium),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _upgradePremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '立即升级 ¥9.9/月起',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitChip(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.white.withAlpha(50)
            : Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: enabled
            ? Border.all(color: Colors.white.withAlpha(100))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.lock,
            color: Colors.white.withAlpha(enabled ? 255 : 150),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(enabled ? 255 : 150),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard(StoneSkin skin, UserData userData) {
    final isPurchased = userData.purchasedSkins.contains(skin.id);
    final isSelected = userData.currentSkin == skin.id;
    final isFree = skin.price == 0;

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
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.style,
                  size: 40,
                  color: isSelected ? AppColors.primary : Colors.grey,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skin.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '已拥有',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      isFree ? '免费' : '¥${skin.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFree ? AppColors.success : AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            // 操作按钮
            if (isPurchased)
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
              ElevatedButton(
                onPressed: isFree
                    ? () => _purchaseSkin(skin)
                    : () => _purchaseSkin(skin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('购买'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
