import 'package:flutter/material.dart';

enum PasswordStrength {
  Weak,
  Medium,
  Strong,
}

class PasswordStrengthChecker {
  static PasswordStrength checkStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.Weak;
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;
    if (hasMinLength) score++;

    if (score >= 4) {
      return PasswordStrength.Strong;
    } else if (score >= 2) {
      return PasswordStrength.Medium;
    } else {
      return PasswordStrength.Weak;
    }
  }

  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.Strong:
        return 'Strong';
      case PasswordStrength.Medium:
        return 'Medium';
      default:
        return 'Weak';
    }
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.Strong:
        return Colors.green;
      case PasswordStrength.Medium:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}