import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, user.uid);
    });
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, result.user!.uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? semester,
    String? phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel user = UserModel(
        uid: result.user!.uid,
        email: email,
        fullName: fullName,
        role: role,
        semester: semester,
        phoneNumber: phoneNumber,
        isVerified: role == 'student' ? true : false,
      );
      await _firestore.collection('users').doc(result.user!.uid).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}