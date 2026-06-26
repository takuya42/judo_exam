import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

const freeAnswerLimit = 30;
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<UserProfile?>.value(null);
  return ref.watch(firestoreProvider).collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists) return UserProfile.initial(user.uid, email: user.email, displayName: user.displayName);
    return UserProfile.fromFirestore(snapshot);
  });
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

class AuthController {
  const AuthController({required this.auth, required this.firestore, required this.googleSignIn});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  Future<AuthSession> signInWithGoogle() async {
    debugPrint('[AuthController] Google sign-in started');
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw const AuthCanceledException();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);
      final profile = await ensureUserDocument(userCredential.user, provider: 'google');
      debugPrint('[AuthController] Google sign-in succeeded uid=${userCredential.user?.uid} isPremium=${profile?.isPremium}');
      return AuthSession(userCredential: userCredential, profile: profile);
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseAuthException during Google sign-in: code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirebaseAuth(error), stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseException during Google sign-in: plugin=${error.plugin} code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirestore(error), stackTrace);
    }
  }

  Future<AuthSession> signInWithEmail(String email, String password) async {
    debugPrint('[AuthController] Email sign-in started email=$email');
    try {
      final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      final profile = await ensureUserDocument(userCredential.user, provider: 'email');
      debugPrint('[AuthController] Email sign-in succeeded uid=${userCredential.user?.uid} isPremium=${profile?.isPremium}');
      return AuthSession(userCredential: userCredential, profile: profile);
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseAuthException during email sign-in: code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirebaseAuth(error), stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseException during email sign-in: plugin=${error.plugin} code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirestore(error), stackTrace);
    }
  }

  Future<AuthSession> createUserWithEmail(String email, String password) async {
    debugPrint('[AuthController] Email registration started email=$email');
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      final profile = await ensureUserDocument(userCredential.user, provider: 'email');
      debugPrint('[AuthController] Email registration succeeded uid=${userCredential.user?.uid} isPremium=${profile?.isPremium}');
      return AuthSession(userCredential: userCredential, profile: profile);
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseAuthException during email registration: code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirebaseAuth(error), stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseException during email registration: plugin=${error.plugin} code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirestore(error), stackTrace);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('[AuthController] Password reset requested email=$email');
    try {
      await auth.sendPasswordResetEmail(email: email);
      debugPrint('[AuthController] Password reset email sent email=$email');
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('[AuthController] FirebaseAuthException during password reset: code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirebaseAuth(error), stackTrace);
    }
  }

  Future<void> signOut() async {
    debugPrint('[AuthController] Sign-out started uid=${auth.currentUser?.uid}');
    await googleSignIn.signOut();
    await auth.signOut();
    debugPrint('[AuthController] Sign-out completed');
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    await firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    await googleSignIn.signOut();
  }

  Future<UserProfile?> ensureUserDocument(User? user, {String? provider}) async {
    if (user == null) return null;
    final ref = firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final resolvedProvider = provider ?? _providerFor(user);
    debugPrint('[AuthController] Ensuring Firestore user document uid=${user.uid} provider=$resolvedProvider');
    try {
      final existing = await ref.get();
      final data = <String, Object?>{
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'provider': resolvedProvider,
        'isPremium': existing.data()?['isPremium'] == true,
        'answerCount': existing.data()?['answerCount'] ?? 0,
        'updatedAt': now,
      };
      if (!existing.exists || existing.data()?['createdAt'] == null) data['createdAt'] = now;
      await ref.set(data, SetOptions(merge: true));
      final snapshot = await ref.get();
      final profile = UserProfile.fromFirestore(snapshot);
      debugPrint('[AuthController] Firestore user document ready uid=${profile.uid} isPremium=${profile.isPremium}');
      return profile;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('[AuthController] Failed to write/read Firestore user document uid=${user.uid}: plugin=${error.plugin} code=${error.code} message=${error.message}');
      Error.throwWithStackTrace(AuthFailure.fromFirestore(error), stackTrace);
    }
  }

  String _providerFor(User user) {
    if (user.providerData.any((info) => info.providerId == GoogleAuthProvider.PROVIDER_ID)) return 'google';
    return 'email';
  }

  Future<bool> canAnswer() async {
    final user = auth.currentUser;
    if (user == null) return false;
    final profile = await ensureUserDocument(user);
    return profile?.isPremium == true || (profile?.answerCount ?? 0) < freeAnswerLimit;
  }

  Future<void> incrementAnswerCount() async {
    final user = auth.currentUser;
    if (user == null) return;
    await ensureUserDocument(user);
    await firestore.collection('users').doc(user.uid).set({
      'answerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setPremium(bool value) async {
    final user = auth.currentUser;
    if (user == null) return;
    await ensureUserDocument(user);
    await firestore.collection('users').doc(user.uid).set({
      'isPremium': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class AuthSession {
  const AuthSession({required this.userCredential, required this.profile});
  final UserCredential userCredential;
  final UserProfile? profile;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});
  factory AuthFailure.fromFirebaseAuth(FirebaseAuthException error) => AuthFailure(_authMessage(error.code), code: error.code);
  factory AuthFailure.fromFirestore(FirebaseException error) => AuthFailure('ユーザー情報の保存・取得に失敗しました（${error.code}）。通信環境やFirestoreの権限設定を確認してください。', code: error.code);
  final String message;
  final String? code;
  @override
  String toString() => message;
}

String _authMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'メールアドレスの形式が正しくありません。';
    case 'user-disabled':
      return 'このアカウントは無効化されています。';
    case 'user-not-found':
    case 'invalid-credential':
      return 'メールアドレスまたはパスワードが正しくありません。';
    case 'wrong-password':
      return 'パスワードが正しくありません。';
    case 'email-already-in-use':
      return 'このメールアドレスはすでに登録されています。ログインをお試しください。';
    case 'weak-password':
      return 'パスワードは6文字以上で、推測されにくいものを設定してください。';
    case 'operation-not-allowed':
      return 'このログイン方法は現在利用できません。Firebase Authenticationの設定を確認してください。';
    case 'account-exists-with-different-credential':
      return '同じメールアドレスのアカウントが別のログイン方法で登録されています。';
    case 'network-request-failed':
      return 'ネットワークに接続できません。通信環境を確認してください。';
    case 'too-many-requests':
      return '試行回数が多すぎます。しばらく時間をおいてから再度お試しください。';
    case 'requires-recent-login':
      return '安全のため再ログインが必要です。ログインし直してからお試しください。';
    default:
      return '認証に失敗しました（$code）。時間をおいて再度お試しください。';
  }
}

class AuthCanceledException implements Exception {
  const AuthCanceledException();
  @override
  String toString() => 'ログインがキャンセルされました。';
}

class UserProfile {
  const UserProfile({required this.uid, this.email, this.displayName, required this.provider, required this.answerCount, required this.isPremium});
  factory UserProfile.initial(String uid, {String? email, String? displayName}) => UserProfile(uid: uid, email: email, displayName: displayName, provider: 'email', answerCount: 0, isPremium: false);
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: (data['uid'] as String?) ?? snapshot.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      provider: (data['provider'] as String?) ?? 'email',
      answerCount: (data['answerCount'] as num?)?.toInt() ?? 0,
      isPremium: data['isPremium'] == true,
    );
  }
  final String uid;
  final String? email;
  final String? displayName;
  final String provider;
  final int answerCount;
  final bool isPremium;
}
