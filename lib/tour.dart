import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dashboard.dart';
import 'login.dart';

class Tour extends StatefulWidget {
  const Tour({Key? key, required this.rowid}) : super(key: key);
  final String? rowid;
  @override
  State<Tour> createState() => _TourState();
}

class _TourState extends State<Tour> {
  int _currentIndex = 1;
  final formKey = GlobalKey<FormState>();
  final _selectedDist = 'KOLKATA';
  List distList = [];
  String endPoint = 'https://synergicportal.in/claim/index.php/api';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String? _currentAddress;
  Position? _currentPosition;
  String? _LatPos;
  String? _LongPos;
  int _rowId = 0;
  var distId;
  String? orgName, orgAddr, pinNo, contPerson, phoneNo, emailId;
  bool value = false;

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    getDistList();
    // GetTourData();
  }

  Future<void> getDistList() async {
    final response = await http.post(Uri.parse(endPoint + '/get_district'));
    var data = jsonDecode(response.body);
    if (data['suc'] > 0) {
      setState(() {
        distList = data['msg'];
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition(
      orgName, orgAddr, distId, pinNo, contPerson, phoneNo, emailId) async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      // print(position);
      _getAddressFromLatLng(_currentPosition!, orgName, orgAddr, distId, pinNo,
          contPerson, phoneNo, emailId);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position, orgName, orgAddr,
      distId, pinNo, contPerson, phoneNo, emailId) async {
    const url = 'https://maps.googleapis.com/maps/api/geocode/json';
    try {
      final response = await http.post(Uri.parse(url +
          '?latlng=' +
          _currentPosition!.latitude.toString() +
          ',' +
          _currentPosition!.longitude.toString() +
          '&key=AIzaSyA1BfzIWaIqGjbmKTW8JMvoQNByl54Bb7o'));
      var data = jsonDecode(response.body);
      // print(data['results'][0]['formatted_address']);
      setState(() {
        _currentAddress = data['results'][0]['formatted_address'];
        _LatPos = _currentPosition!.latitude.toString();
        _LongPos = _currentPosition!.longitude.toString();
      });

      final SharedPreferences prefs = await _prefs;
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      final empNo = prefs.getString('empNo');

      var map = new Map<String, dynamic>();
      map['id'] = _rowId.toString();
      map['emp_code'] = empNo;
      map['visit_dt'] =
          DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now());
      map['org_name'] = orgName.toString();
      map['org_addr'] = orgAddr.toString();
      map['district_code'] = distId.toString();
      map['pin_no'] = pinNo.toString();
      map['contact_person'] = contPerson.toString();
      map['phone_no'] = phoneNo.toString();
      map['email_id'] = emailId.toString();
      map['location'] = data['results'][0]['formatted_address'];
      map['lat_pos'] = _currentPosition!.latitude.toString();
      map['long_pos'] = _currentPosition!.longitude.toString();
      map['curr_dt'] = DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now());
      map['user'] = empNo.toString();

      final resDt =
          await http.post(Uri.parse(endPoint + '/visit_mgmt_save'), body: map);
      // print(resDt.body);
      // print(jsonDecode(resDt.body));
      var dt = jsonDecode(resDt.body);
      if (dt['suc'] > 0) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (BuildContext context) {
          return const Dashboard(docKey: 1);
        }), (route) => false);
      }
      // print(dt);
      // if (dt['suc'] > 0) {
      //   await getUserData();
      // }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Future<void> saveAttendance() async {
  //   await _getCurrentPosition();
  // }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    TextEditingController _orgName = TextEditingController();
    TextEditingController _orgAddr = TextEditingController();
    TextEditingController _pinNo = TextEditingController();
    TextEditingController _contPerson = TextEditingController();
    TextEditingController _phoneNo = TextEditingController();
    TextEditingController _emailId = TextEditingController();

    Future GetTourData() async {
      if (widget.rowid != '0') {
        final response = await http.get(Uri.parse(
            endPoint + '/visit_mgmt_dtls?id=' + widget.rowid.toString()));
        var data = jsonDecode(response.body);
        if (data['suc'] > 0) {
          // setState(() {
          orgName = data['msg'][0]['org_name'].toString();
          orgAddr = data['msg'][0]['org_addr'].toString();
          pinNo = data['msg'][0]['pin_no'].toString();
          contPerson = data['msg'][0]['contact_person'].toString();
          phoneNo = data['msg'][0]['phone_no'].toString();
          emailId = data['msg'][0]['email_id'].toString();

          _orgName.text = orgName!;
          _orgAddr.text = orgAddr!;
          _pinNo.text = pinNo!;
          _contPerson.text = contPerson!;
          _phoneNo.text = phoneNo!;
          _emailId.text = emailId!;
          _rowId = int.parse(data['msg'][0]['sl_no']);
          // });
        }
      }
    }

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 10,
          backgroundColor: Colors.deepPurpleAccent,
          leading: Container(
            padding: EdgeInsets.all(5),
            child: Image.asset('assets/logo.png'),
          ),
          centerTitle: true,
          title: const Text('STAMS'),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return const Login();
                  }), (route) => false);
                },
                icon: const Icon(Icons.logout_sharp))
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Visit Managment',
                        style: TextStyle(
                            color: Colors.black54,
                            fontFamily: "NexaRegular",
                            fontSize: 20),
                      ),
                    ),
                    Form(
                      key: formKey,
                      child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(children: [
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                              controller: _orgName,
                              decoration: const InputDecoration(
                                  labelText: 'Organization Name',
                                  border: OutlineInputBorder()),
                              validator: (value) {
                                // orgName = value;
                                if (value!.isEmpty) {
                                  return "Enter Organization Name";
                                } else {
                                  return null;
                                }
                              },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                              controller: _orgAddr,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: 4,
                              minLines: 2,
                              // validator: (value) {
                              //   if (value!.isEmpty) {
                              //     return "Supply Address";
                              //   } else {
                              //     return null;
                              //   }
                              // },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            DropdownButtonFormField(
                                value: distId,
                                decoration: const InputDecoration(
                                    label: Text('Select District'),
                                    border: OutlineInputBorder()),
                                items: distList.map((e) {
                                  return DropdownMenuItem(
                                    child: Text(e['district_name']),
                                    value: e['id'],
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  print(val);
                                  // orgName = _orgName.text;
                                  setState(() {
                                    print(_orgName.text);
                                    distId = val!;
                                    _orgName.text = _orgName.text;
                                    // _orgName.value =
                                    //     TextEditingController.fromValue(
                                    //             TextEditingValue(
                                    //                 text: _orgName.text))
                                    //         .value;
                                    // orgAddr = _orgAddr.text;
                                    // pinNo = _pinNo.text;
                                    // contPerson = _contPerson.text;
                                    // phoneNo = _phoneNo.text;
                                    // emailId = _emailId.text;
                                  });
                                }),
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                              controller: _pinNo,
                              decoration: const InputDecoration(
                                  labelText: 'PIN No.',
                                  border: OutlineInputBorder()),
                              // validator: (value) {
                              //   if (value!.isEmpty) {
                              //     return "Enter Pin No";
                              //   } else {
                              //     return null;
                              //   }
                              // },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                              controller: _contPerson,
                              decoration: const InputDecoration(
                                  labelText: 'Contact Person',
                                  border: OutlineInputBorder()),
                              // validator: (value) {
                              //   if (value!.isEmpty) {
                              //     return "Enter Contact Person Name";
                              //   } else {
                              //     return null;
                              //   }
                              // },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                              controller: _phoneNo,
                              decoration: const InputDecoration(
                                  labelText: 'Phone No.',
                                  border: OutlineInputBorder()),
                              // validator: (value) {
                              //   if (value!.isEmpty) {
                              //     return "Enter Phone No.";
                              //   } else {
                              //     return null;
                              //   }
                              // },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            TextFormField(
                                controller: _emailId,
                                decoration: const InputDecoration(
                                    labelText: 'Email ID',
                                    border: OutlineInputBorder())),
                            const SizedBox(
                              height: 20.0,
                            ),
                            ListTile(
                              leading: Checkbox(
                                value: value,
                                onChanged: (val) {
                                  setState(() {
                                    value = val!;
                                  });
                                },
                              ),
                              title: const Text(
                                'Out',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  var orgName = _orgName.text,
                                      orgAddr = _orgAddr.text,
                                      pinNo = _pinNo.text,
                                      contPerson = _contPerson.text,
                                      phoneNo = _phoneNo.text,
                                      emailId = _emailId.text;
                                  _getCurrentPosition(orgName, orgAddr, distId,
                                      pinNo, contPerson, phoneNo, emailId);
                                }
                              },
                              // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
                              style: ElevatedButton.styleFrom(
                                  primary:
                                      const Color.fromARGB(255, 90, 66, 138),
                                  elevation: 12.0,
                                  textStyle:
                                      const TextStyle(color: Colors.white),
                                  minimumSize: const Size(150, 40)),
                              child: const Text('Submit'),
                            )
                          ])),
                    )
                  ],
                ))));
  }
}
