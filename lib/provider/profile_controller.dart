import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends ChangeNotifier {
  static const String _fullNameKey = 'profile_full_name';
  static const String _emailKey = 'profile_email';
  static const String _phoneKey = 'profile_phone';
  static const String _businessKey = 'profile_business';
  static const String _roleKey = 'profile_role';
  static const String _businessTypeKey = 'profile_business_type';
  static const String _locationKey = 'profile_location';
  static const String _avatarBase64Key = 'profile_avatar_base64';
  static const String _avatarPathKey = 'profile_avatar_path'; // legacy key

  bool _loaded = false;
  bool get isLoaded => _loaded;

  String fullName = '';
  String email = '';
  String phone = '';
  String businessName = '';
  String role = '';
  String businessType = '';
  String location = '';
  Uint8List? avatarBytes;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    fullName = prefs.getString(_fullNameKey) ?? '';
    email = prefs.getString(_emailKey) ?? '';
    phone = prefs.getString(_phoneKey) ?? '';
    businessName = prefs.getString(_businessKey) ?? '';
    role = prefs.getString(_roleKey) ?? '';
    businessType = prefs.getString(_businessTypeKey) ?? '';
    location = prefs.getString(_locationKey) ?? '';
    final avatarBase64 = prefs.getString(_avatarBase64Key) ?? '';
    if (avatarBase64.isNotEmpty) {
      try {
        avatarBytes = base64Decode(avatarBase64);
      } catch (_) {
        avatarBytes = null;
        await prefs.remove(_avatarBase64Key);
      }
    } else {
      avatarBytes = null;
    }

    if (prefs.containsKey(_avatarPathKey)) {
      await prefs.remove(_avatarPathKey);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String businessName,
    required String role,
    required String businessType,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_phoneKey, phone);
    await prefs.setString(_businessKey, businessName);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_businessTypeKey, businessType);
    await prefs.setString(_locationKey, location);

    this.fullName = fullName;
    this.email = email;
    this.phone = phone;
    this.businessName = businessName;
    this.role = role;
    this.businessType = businessType;
    this.location = location;
    notifyListeners();
  }

  Future<void> updateAvatarBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarBase64Key, base64Encode(bytes));
    avatarBytes = bytes;
    notifyListeners();
  }

  Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarBase64Key);
    await prefs.remove(_avatarPathKey);
    avatarBytes = null;
    notifyListeners();
  }
}
