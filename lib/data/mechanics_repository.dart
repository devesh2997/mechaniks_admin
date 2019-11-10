import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mechaniks_admin/models/mechanic.dart';

class MechanicsRepository extends ChangeNotifier {
  List<Mechanic> mechanics = [];
  Firestore _db;
  FirebaseAuth _auth;

  MechanicsRepository.instance()
      : mechanics = [],
        _db = Firestore.instance, _auth= FirebaseAuth.instance {
    _db.collection('mechanics').snapshots().listen(_onMechanicsDataChanged);
  }

  Future<void> _onMechanicsDataChanged(QuerySnapshot querySnapshot) async {
    List<Mechanic> m = [];
    querySnapshot.documents
        .forEach((doc) => m.add(Mechanic.fromFirestore(doc)));

    mechanics = m;
    notifyListeners();
  }

  Future<bool> addMechanic(Mechanic mechanic, String password) async {
    FirebaseUser user = await _auth.createUserWithEmailAndPassword(email:mechanic.email, password:password );
    await _db.collection('mechanics').document(user.uid).setData(mechanic.toMapForFirestore());
    return true;
  }

  Future<bool> deleteMechanic(Mechanic mechanic) async {
    await _db.collection('mechanics').document(mechanic.id).delete();
    return true;
  }
}
