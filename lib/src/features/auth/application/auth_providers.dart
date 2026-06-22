import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (!snapshot.exists) return UserProfile.initial(user.uid);
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

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw const AuthCanceledException();
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await auth.signInWithCredential(credential);
    await ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
    await ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> createUserWithEmail(String email, String password) async {
    final userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
    await ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) => auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    await firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    await googleSignIn.signOut();
  }

  Future<void> ensureUserDocument(User? user) async {
    if (user == null) return;
    final ref = firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'answerCount': 0,
      'isPremium': false,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<bool> canAnswer() async {
    final user = auth.currentUser;
    if (user == null) return false;
    await ensureUserDocument(user);
    final snapshot = await firestore.collection('users').doc(user.uid).get();
    final profile = snapshot.exists ? UserProfile.fromFirestore(snapshot) : UserProfile.initial(user.uid);
    return profile.isPremium || profile.answerCount < freeAnswerLimit;
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

  Future<void> restorePurchase() async => setPremium(true);

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

class AuthCanceledException implements Exception {
  const AuthCanceledException();
}

class UserProfile {
  const UserProfile({required this.uid, required this.answerCount, required this.isPremium});
  factory UserProfile.initial(String uid) => UserProfile(uid: uid, answerCount: 0, isPremium: false);
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: snapshot.id,
      answerCount: (data['answerCount'] as num?)?.toInt() ?? 0,
      isPremium: data['isPremium'] == true,
    );
  }
  final String uid;
  final int answerCount;
  final bool isPremium;
}
