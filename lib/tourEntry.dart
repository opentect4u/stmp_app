import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';

class tourEntry extends StatefulWidget {
  const tourEntry({Key? key, required this.rowid}) : super(key: key);
  final int rowid;

  @override
  State<tourEntry> createState() => _tourEntryState();
}

class _tourEntryState extends State<tourEntry> {
  final _orgName = TextEditingController();
  final _orgAddr = TextEditingController();
  final _orgPin = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  List distList = [];
  String endPoint = 'https://synergicportal.in/claim/index.php/api';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final formKey = GlobalKey<FormState>();

  bool? _chkVal = false;
  String? distId;
  String? _currentAddress;
  Position? _currentPosition;
  String? _LatPos;
  String? _LongPos;
  int _rowId = 0;
  String? inOutFlag = 'I';
  String? _outTime;

  @override
  void dispose() {
    // TODO: implement dispose
    _orgName.dispose();
    _orgAddr.dispose();
    _orgPin.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getDistList();
    // TODO: implement initState
    super.initState();
    GetTourData();
  }

  Future GetTourData() async {
    if (widget.rowid != 0) {
      print('in if part');
      final response = await http.get(Uri.parse(
          endPoint + '/visit_mgmt_dtls?id=' + widget.rowid.toString()));
      var data = jsonDecode(response.body);
      if (data['suc'] > 0) {
        setState(() {
          // orgName = data['msg'][0]['org_name'].toString();
          // orgAddr = data['msg'][0]['org_addr'].toString();
          // pinNo = data['msg'][0]['pin_no'].toString();
          // contPerson = data['msg'][0]['contact_person'].toString();
          // phoneNo = data['msg'][0]['phone_no'].toString();
          // emailId = data['msg'][0]['email_id'].toString();

          _orgName.text = data['msg'][0]['org_name'].toString();
          _orgAddr.text = data['msg'][0]['org_addr'].toString();
          _orgPin.text = data['msg'][0]['pin_no'].toString();
          _contactName.text = data['msg'][0]['contact_person'].toString();
          _contactPhone.text = data['msg'][0]['phone_no'].toString();
          _contactEmail.text = data['msg'][0]['email_id'].toString();
          _rowId = int.parse(data['msg'][0]['sl_no']);
          inOutFlag = data['msg'][0]['in_out_flag'].toString();
          _outTime = data['msg'][0]['out_time'].toString();
        });
      }
    }
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
      map['in_time'] = DateFormat('hh:mm:ss').format(DateTime.now());
      map['out_time'] = DateFormat('hh:mm:ss').format(DateTime.now());
      map['in_out_flag'] = _chkVal! ? 'O' : 'I';
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

  @override
  Widget build(BuildContext context) {
    // GetTourData();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: ListView(children: [
            const Text('Add Tour Details Below'),
            const SizedBox(
              height: 40,
            ),
            MyInputForm(
              fieldName: 'Organization Name',
              myController: _orgName,
              icon: Icons.home_work_outlined,
              prefixIconColor: Colors.deepPurple,
              isVal: true,
              keyType: TextInputType.name,
            ),
            const SizedBox(
              height: 20,
            ),
            MyInputForm(
              fieldName: 'Organization Address',
              myController: _orgAddr,
              icon: Icons.home,
              prefixIconColor: Colors.deepPurple,
              isVal: false,
              keyType: TextInputType.multiline,
              maxLine: 4,
              minLine: 2,
            ),
            const SizedBox(
              height: 20,
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
                  setState(() {
                    distId = val as String;
                  });
                }),
            const SizedBox(
              height: 20,
            ),
            MyInputForm(
              fieldName: 'PIN No.',
              myController: _orgPin,
              icon: Icons.pin_drop_outlined,
              prefixIconColor: Colors.deepPurple,
              isVal: false,
              keyType: TextInputType.number,
            ),
            const SizedBox(
              height: 20,
            ),
            MyInputForm(
              fieldName: 'Contact Person',
              myController: _contactName,
              icon: Icons.person_outlined,
              prefixIconColor: Colors.deepPurple,
              isVal: false,
              keyType: TextInputType.name,
            ),
            const SizedBox(
              height: 20,
            ),
            MyInputForm(
              fieldName: 'Phone No.',
              myController: _contactPhone,
              icon: Icons.phone_android,
              prefixIconColor: Colors.deepPurple,
              isVal: false,
              keyType: TextInputType.phone,
            ),
            const SizedBox(
              height: 20,
            ),
            MyInputForm(
              fieldName: 'Email Id',
              myController: _contactEmail,
              icon: Icons.email_outlined,
              prefixIconColor: Colors.deepPurple,
              isVal: false,
              keyType: TextInputType.emailAddress,
            ),
            if (_rowId > 0 && inOutFlag != 'O')
              CheckboxListTile(
                checkColor: Colors.white,
                activeColor: Colors.deepPurple,
                value: _chkVal,
                title: const Text('OUT'),
                onChanged: (val) {
                  setState(
                    () {
                      _chkVal = val;
                    },
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(
              height: 20,
            ),
            if (inOutFlag != 'I')
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("OUT Time",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 5)),
                    Text(
                      DateFormat('hh:mm a').format(
                          DateTime.parse('1996-01-01 ' + _outTime.toString())),
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 7),
                    ),
                  ]),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  var orgName = _orgName.text,
                      orgAddr = _orgAddr.text,
                      pinNo = _orgPin.text,
                      contPerson = _contactName.text,
                      phoneNo = _contactPhone.text,
                      emailId = _contactEmail.text;
                  _getCurrentPosition(orgName, orgAddr, distId, pinNo,
                      contPerson, phoneNo, emailId);
                }
              },
              // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
              style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 90, 66, 138),
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white),
                  minimumSize: const Size(150, 40)),
              child: const Text('Submit'),
            ),
          ]),
        ),
      ),
    );
  }
}

class MyInputForm extends StatelessWidget {
  const MyInputForm(
      {Key? key,
      required this.fieldName,
      required this.myController,
      required this.icon,
      required prefixIconColor,
      this.preIconColor = Colors.deepPurple,
      required this.keyType,
      this.maxLine = 1,
      this.minLine = 1,
      this.isVal = false})
      : super(key: key);

  final String fieldName;
  final TextEditingController myController;
  final IconData icon;
  final Color preIconColor;
  final TextInputType keyType;
  final int maxLine;
  final int minLine;
  final bool isVal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: myController,
      decoration: InputDecoration(
          labelText: fieldName,
          prefixIcon: Icon(
            icon,
            color: preIconColor,
          ),
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple.shade300)),
          labelStyle: const TextStyle(color: Colors.black54)),
      validator: (val) {
        if (isVal) {
          if (val!.isEmpty) {
            return "Enter Organization Name";
          } else {
            return null;
          }
        } else {
          return null;
        }
      },
      keyboardType: keyType,
      maxLines: maxLine,
      minLines: minLine,
    );
  }
}

class ShowLoader extends StatelessWidget {
  const ShowLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 1.0,
      alignment: Alignment.topCenter,
      color: Colors.deepPurpleAccent,
      child: const Center(
        child: SpinKitRotatingCircle(
          color: Colors.white,
          size: 80.0,
        ),
      ),
    );
  }
}
