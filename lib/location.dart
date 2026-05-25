// Representation of Firestore Documents
// Test
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';

class Location {
  Location({this.pos, this.userId});

  GeoPoint? pos;
  int? userId;

  factory Location.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    return Location(
      pos: data?['location'] as GeoPoint?,
      userId: data?['userId'] as int?,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {if (pos != null) "pos": pos, if (userId != null) "userId": userId};
  }

  @override
  String toString() => "Location[pos=$pos, userId=$userId]";
}
