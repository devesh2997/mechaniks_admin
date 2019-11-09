import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String geohash;
  final GeoPoint geopoint;

  Location(this.geohash, this.geopoint);

  factory Location.fromMap(Map data){
    return Location(data['geohash'],data['geopoint']);
  }

  Map<String,dynamic> toMapForFirestore(){
    Map<String,dynamic> locationMap = Map<String,dynamic>();
    locationMap['geohash'] = this.geohash;
    locationMap['geopoint'] = this.geopoint;

    return locationMap;
  }
}