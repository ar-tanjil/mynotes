import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_execption.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection("notes");

  Stream<Iterable<CloudNote>> allNotes({required String userId}) =>
      notes.snapshots().map((event) => event.docs
          .map((doc) => CloudNote.fromSnapshot(doc))
          .where((note) => note.userId == userId));

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  FirebaseCloudStorage._sharedInstance();

  factory FirebaseCloudStorage() => _shared;

  Future<CloudNote> createNewNote({required String userId}) async {
    final document = await notes.add({
      fieldUserId: userId,
      fieldText: '',
    });

    final fetchedNote = await document.get();

    return CloudNote(
      id: fetchedNote.id,
      userId: userId,
      text: '',
    );
  }

  Future<Iterable<CloudNote>> getNotes({
    required String userId,
  }) async {
    try {
      return await notes
          .where(
            fieldUserId,
            isEqualTo: userId,
          )
          .get()
          .then((value) => value.docs.map((doc) {
                return CloudNote(
                  id: doc.id,
                  userId: doc.data()[fieldUserId],
                  text: doc.data()[fieldText] as String,
                );
              }));
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Future<void> updateNote({
    required noteId,
    required String text,
  }) async {
    try {
      await notes.doc(noteId).update({fieldText: text});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({
    required String noteId,
  }) async {
    try {
      await notes.doc(noteId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }
}
