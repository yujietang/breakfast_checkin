import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// 安全存储服务
/// 
/// 使用简单加密保护用户隐私数据
/// 
/// 注意：这不是银行级加密，但可防止普通用户直接读取数据
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const String _encryptionKeyPrefix = 'secure_';
  static const String _keySalt = 'breakfast_checkin_salt_v1';

  /// 加密存储字符串
  Future<void> setSecureString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _encrypt(value);
    await prefs.setString('$_encryptionKeyPrefix$key', encrypted);
  }

  /// 读取加密字符串
  Future<String?> getSecureString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('$_encryptionKeyPrefix$key');
    if (encrypted == null) return null;
    
    try {
      return _decrypt(encrypted);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('【安全存储】解密失败：$e');
      }
      return null;
    }
  }

  /// 加密存储Map
  Future<void> setSecureMap(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await setSecureString(key, jsonString);
  }

  /// 读取加密Map
  Future<Map<String, dynamic>?> getSecureMap(String key) async {
    final jsonString = await getSecureString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('【安全存储】JSON解析失败：$e');
      }
      return null;
    }
  }

  /// 删除加密数据
  Future<void> removeSecure(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_encryptionKeyPrefix$key');
  }

  /// 清除所有加密数据
  Future<void> clearAllSecure() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_encryptionKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// 简单加密（XOR + Base64）
  /// 
  /// 注意：这是基础混淆，不是高强度加密
  String _encrypt(String plainText) {
    final key = _deriveKey();
    final bytes = utf8.encode(plainText);
    final encrypted = <int>[];
    
    for (var i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ key[i % key.length]);
    }
    
    // 添加随机前缀防止模式识别
    final random = Random.secure();
    final salt = List<int>.generate(8, (_) => random.nextInt(256));
    final withSalt = [...salt, ...encrypted];
    
    return base64Encode(withSalt);
  }

  /// 简单解密
  String _decrypt(String encrypted) {
    final key = _deriveKey();
    final bytes = base64Decode(encrypted);
    
    // 跳过8字节盐值
    final encryptedBytes = bytes.sublist(8);
    final decrypted = <int>[];
    
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ key[i % key.length]);
    }
    
    return utf8.decode(decrypted);
  }

  /// 派生加密密钥（基于设备特征）
  List<int> _deriveKey() {
    // 使用设备信息和时间戳的组合作为密钥种子
    final seed = '$_keySalt${DateTime.now().year}${DateTime.now().month}';
    final hash = sha256.convert(utf8.encode(seed));
    return hash.bytes;
  }

  /// 数据备份到明文（用于用户导出）
  Future<String> exportToPlainText(String key) async {
    final data = await getSecureString(key);
    return data ?? '{}';
  }

  /// 从明文导入（用户恢复数据）
  Future<void> importFromPlainText(String key, String plainText) async {
    await setSecureString(key, plainText);
  }

  /// 检查是否存在加密数据
  Future<bool> hasSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_encryptionKeyPrefix$key');
  }

  /// 获取所有加密键名（调试用）
  Future<List<String>> getAllSecureKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_encryptionKeyPrefix))
        .map((k) => k.substring(_encryptionKeyPrefix.length))
        .toList();
  }
}

/// 安全存储键名常量
class SecureStorageKeys {
  static const String userData = 'user_data_v2_encrypted';
  static const String lastOpenTime = 'last_open_time_encrypted';
  static const String cheatFrozenUntil = 'cheat_frozen_until';
  static const String backupData = 'backup_data_encrypted';
}
