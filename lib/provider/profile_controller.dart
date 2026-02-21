import 'dart:io';

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
  static const String _avatarPathKey = 'profile_avatar_path';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  String fullName = '';
  String email = '';
  String phone = '';
  String businessName = '';
  String role = '';
  String businessType = '';
  String location = '';
  String avatarPath = '';

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    fullName = prefs.getString(_fullNameKey) ?? '';
    email = prefs.getString(_emailKey) ?? '';
    phone = prefs.getString(_phoneKey) ?? '';
    businessName = prefs.getString(_businessKey) ?? '';
    role = prefs.getString(_roleKey) ?? '';
    businessType = prefs.getString(_businessTypeKey) ?? '';
    location = prefs.getString(_locationKey) ?? '';
    avatarPath = prefs.getString(_avatarPathKey) ?? '';
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

  Future<void> updateAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
    avatarPath = path;
    notifyListeners();
  }

  File? get avatarFile {
    if (avatarPath.isEmpty) return null;
    final file = File(avatarPath);
    return file.existsSync() ? file : null;
  }
}
