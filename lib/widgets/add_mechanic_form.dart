import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mechaniks_admin/data/mechanics_repository.dart';
import 'package:mechaniks_admin/models/mechanic.dart';
import 'package:mechaniks_admin/utils/index.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

final GlobalKey<FormState> formKey = GlobalKey<FormState>();

class AddMechanicForm extends StatefulWidget {
  final Function callback;

  const AddMechanicForm({Key key, this.callback}) : super(key: key);
  @override
  _AddMechanicFormState createState() => _AddMechanicFormState();
}

class _AddMechanicFormState extends State<AddMechanicForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  GeoFirePoint location;

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;

  String address;

  bool showMarker;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  bool submittingMechanic;

  @override
  void initState() {
    super.initState();
    location = GeoFirePoint(0, 0);
    submittingMechanic = false;
    showMarker = false;
    address = "";
    initLocation();
  }

  Future<void> updateAddress() async {
    String add = await getAddressFromGeoFirePoint(location);
    setState(() {
      address = add;
    });
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      setState(() {
        location = GeoFirePoint(latitude, longitude);
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> initLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    double latitude = position.latitude;
    double longitude = position.longitude;
    setState(() {
      location = GeoFirePoint(latitude, longitude);
    });
    await updateAddress();

    CameraPosition cameraPosition =
        CameraPosition(target: LatLng(latitude, longitude), zoom: 14.4746);
    if (mapController != null) {
      CameraUpdate cameraUpdate =
          CameraUpdate.newCameraPosition(cameraPosition);
      await mapController.moveCamera(cameraUpdate);
      setState(() {
        showMarker = true;
      });
    }
  }

  saveMechanic() async {
    var form = formKey.currentState;
    if (form.validate()) {
      setState(() {
        submittingMechanic = true;
      });
      Map<String, dynamic> mechanicData = Map<String, dynamic>();
      mechanicData['name'] = nameController.value.text;
      mechanicData['mobile'] = '+91' + mobileController.value.text;
      mechanicData['location'] = location.data;
      Mechanic mechanic = Mechanic.fromMap(mechanicData);
      bool result =
          await Provider.of<MechanicsRepository>(context).addMechanic(mechanic);
      if (result)
        Navigator.of(context).pop();
      else {
        setState(() {
          submittingMechanic = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Marker marker = Marker(
      markerId: MarkerId('loc'),
      position: LatLng(location.latitude, location.longitude),
    );
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 50,
          ),
          Text(
            'ADD MECHANIC',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Form(
                key: formKey,
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      margin: EdgeInsets.only(bottom: 15),
                      color: Colors.white,
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: size.height * 0.5,
                            child: GoogleMap(
                              onCameraMove: (cameraPosition) {
                                updateLocation(cameraPosition.target.latitude,
                                    cameraPosition.target.longitude);
                              },
                              onCameraIdle: () {
                                updateAddress();
                              },
                              gestureRecognizers: Set()
                                ..add(Factory<PanGestureRecognizer>(
                                    () => PanGestureRecognizer()))
                                ..add(Factory<ScaleGestureRecognizer>(
                                    () => ScaleGestureRecognizer()))
                                ..add(Factory<TapGestureRecognizer>(
                                    () => TapGestureRecognizer()))
                                ..add(Factory<VerticalDragGestureRecognizer>(
                                    () => VerticalDragGestureRecognizer())),
                              myLocationEnabled: true,
                              scrollGesturesEnabled: true,
                              mapType: MapType.normal,
                              markers: showMarker
                                  ? Set<Marker>.from([marker])
                                  : Set(),
                              initialCameraPosition: _kGooglePlex,
                              onMapCreated: (GoogleMapController controller) {
                                _controller.complete(controller);
                                setState(() {
                                  mapController = controller;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 5),
                          if (address != null && address.length > 0)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Location : '),
                                SizedBox(
                                  width: 5,
                                ),
                                Flexible(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        address,
                                        maxLines: 5,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          SizedBox(height: 5),
                          StringInputField(
                            label: "FULL NAME",
                            controller: nameController,
                          ),
                          SizedBox(height: 5),
                          MobileInputField(
                            controller: mobileController,
                          ),
                        ],
                      ),
                    ),
                    if (submittingMechanic)
                      CircularProgressIndicator()
                    else
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: MaterialButton(
                                padding: EdgeInsets.all(0),
                                child: Text("CANCEL"),
                                onPressed: () {
                                  if (Navigator.of(context).canPop())
                                    Navigator.of(context).pop();
                                },
                              ),
                            ),
                            Expanded(
                              child: MaterialButton(
                                padding: EdgeInsets.all(0),
                                color: getPrimaryColor(),
                                child: Text(
                                  "SAVE",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  saveMechanic();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class StringInputField extends StatelessWidget {
  final Function validator;
  final String label;
  final TextEditingController controller;
  StringInputField(
      {@required this.label, this.validator, @required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w100,
          fontSize: 14,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        alignLabelWithHint: true,
      ),
      validator: validator == null
          ? (value) {
              if (value.isEmpty) {
                return 'Enter valid $label';
              }
              return null;
            }
          : validator,
    );
  }
}

class MobileInputField extends StatelessWidget {
  final TextEditingController controller;
  MobileInputField({@required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: controller,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
          labelText: "MOBILE",
          labelStyle: TextStyle(
            fontWeight: FontWeight.w100,
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
          prefixText: "+91 ",
          alignLabelWithHint: true,
          focusColor: Colors.black),
      validator: (value) {
        if (value.isEmpty || value.length != 10) {
          return 'Enter valid Mobile number.';
        }
        return null;
      },
    );
  }
}
