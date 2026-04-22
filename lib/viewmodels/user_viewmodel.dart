import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? phone;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String nativeLanguage;
  final String targetLevel; // beginner, intermediate, advanced
  final int dailyGoal;
  final int totalWordsLearned;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final DateTime createdAt;
  final bool isProfileComplete;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    this.phone,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.nativeLanguage = 'vi',
    this.targetLevel = 'beginner',
    this.dailyGoal = 10,
    this.totalWordsLearned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    required this.createdAt,
    this.isProfileComplete = false,
    this.preferences = const {},
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'],
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      nativeLanguage: data['nativeLanguage'] ?? 'vi',
      targetLevel: data['targetLevel'] ?? 'beginner',
      dailyGoal: data['dailyGoal'] ?? 10,
      totalWordsLearned: data['totalWordsLearned'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastStudyDate: data['lastStudyDate'] != null
          ? (data['lastStudyDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isProfileComplete: data['isProfileComplete'] ?? false,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'nativeLanguage': nativeLanguage,
      'targetLevel': targetLevel,
      'dailyGoal': dailyGoal,
      'totalWordsLearned': totalWordsLearned,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isProfileComplete': isProfileComplete,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    String? phone,
    String? nativeLanguage,
    String? targetLevel,
    int? dailyGoal,
    int? totalWordsLearned,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    bool? isProfileComplete,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLevel: targetLevel ?? this.targetLevel,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      preferences: preferences ?? this.preferences,
    );
  }
}