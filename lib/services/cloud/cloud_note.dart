import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

@immutable
class CloudNote {
  final String id;
  final String userId;
  final String text;

  const CloudNote({
    required this.id,
    required this.userId,
    required this.text,
  });

  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        userId = snapshot.data()[fieldUserId],
        text = snapshot.data()[fieldText] as String;

  @override
  String toString() {
    return "id: $id, userId: $userId, text: ${text.substring(0, 1)}";
  }
}
