import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:slide_to_act/slide_to_act.dart';
// import 'package:geolocator_android/geolocator_android.dart';

class Attendance extends StatefulWidget {
  const Attendance({Key? key}) : super(key: key);

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
// VARIABLES //
  String? _empName;
  String? _empNo;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String? _ckhIn = '--/--';
  String? _ckhOut = '--/--';
  int _rowId = 0;
  String endPoint = 'https://synergicportal.in/claim/index.php/api';
  String? _currentAddress;
  Position? _currentPosition;
  String? _LatPos;
  String? _LongPos;
// END //

// ON-INIT //
  @override
  // ignore: must_call_super
  void initState() {
    super.initState();
    getUserData();
  }
// END //

  Future<void> getUserData() async {
    final SharedPreferences prefs = await _prefs;
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    final empName = prefs.getString('empName');
    final empNo = prefs.getString('empNo');

    setState(() {
      _empName = empName;
      _empNo = empNo;
    });

    var map = new Map<String, dynamic>();
    // print(_empNo);
    map['emp_no'] = empNo;
    final response =
        await http.post(Uri.parse(endPoint + '/atten_dtls'), body: map);
    var data = jsonDecode(response.body);

    if (data['suc'] > 0) {
      if (data['msg'].length > 0) {
        setState(() {
          _ckhIn = data['msg'][0]['in_time'] != null
              ? DateFormat('hh:mm').format(DateTime.parse(
                  data['msg'][0]['atten_dt'] + ' ' + data['msg'][0]['in_time']))
              : _ckhIn;
          _ckhOut = data['msg'][0]['out_time'] != null
              ? DateFormat('hh:mm').format(DateTime.parse(data['msg'][0]
                      ['atten_dt'] +
                  ' ' +
                  data['msg'][0]['out_time']))
              : _ckhOut;
          _rowId = int.parse(data['msg'][0]['id']) > 0
              ? int.parse(data['msg'][0]['id'])
              : 0;
        });
      }
      // print();
    }
    // setState(() => _empName = empName);
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

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
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

      var map = new Map<String, dynamic>();
      map['id'] = _rowId.toString();
      map['emp_code'] = _empNo;
      map['emp_name'] = _empName;
      map['in_time'] = DateFormat('hh:mm:ss').format(DateTime.now());
      map['out_time'] = DateFormat('hh:mm:ss').format(DateTime.now());
      map['in_location'] = data['results'][0]['formatted_address'];
      map['in_lat'] = _currentPosition!.latitude.toString();
      map['in_long'] = _currentPosition!.longitude.toString();

      final resDt =
          await http.post(Uri.parse(endPoint + '/atten_save'), body: map);
      // print(resDt.body);
      // print(jsonDecode(resDt.body));
      var dt = jsonDecode(resDt.body);
      if (dt['suc'] > 0) {
        await getUserData();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> saveAttendance() async {
    await _getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Welcome',
                style: TextStyle(
                    color: Colors.black54,
                    fontFamily: "NexaRegular",
                    fontSize: 20),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_empName',
                style: const TextStyle(fontFamily: "NexaRegular", fontSize: 25),
              ),
            ),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 60),
              child: const Text(
                "Today's Status",
                style: TextStyle(fontFamily: "NexaRegular", fontSize: 25),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 60),
              height: 150,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 2))
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'IN',
                        style: TextStyle(
                            fontFamily: 'NexaRegular',
                            fontSize: 20,
                            color: Colors.black54),
                      ),
                      Text('$_ckhIn',
                          style: const TextStyle(
                              fontFamily: 'NexaBold', fontSize: 25))
                    ],
                  )),
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('OUT',
                          style: TextStyle(
                              fontFamily: 'NexaRegular',
                              fontSize: 20,
                              color: Colors.black54)),
                      Text('$_ckhOut',
                          style: const TextStyle(
                              fontFamily: 'NexaBold', fontSize: 25))
                    ],
                  ))
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                    text: DateTime.now().day.toString(),
                    style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 20,
                        fontFamily: 'NexaBold'),
                    children: [
                      TextSpan(
                        text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontFamily: 'NexaBold'),
                      )
                    ]),
              ),
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: const TextStyle(
                          fontSize: 18,
                          fontFamily: "NexaRegular",
                          color: Colors.black54),
                    ),
                  );
                }),
            if (_ckhOut == '--/--')
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: Builder(builder: (context) {
                  final GlobalKey<SlideActionState> key = GlobalKey();

                  return SlideAction(
                    text: _rowId > 0 ? "Slide to Out" : "Slide to In",
                    textStyle: const TextStyle(
                        color: Colors.black45,
                        fontSize: 20,
                        fontFamily: "NexaRegular"),
                    outerColor: Colors.white,
                    innerColor: Colors.deepPurple,
                    key: key,
                    onSubmit: () {
                      // var _time = DateFormat('hh:mm').format(DateTime.now());
                      // print(DateFormat('yyyy-MM-dd hh:mm:ss')
                      //     .format(DateTime.now()));
                      saveAttendance();
                    },
                  );
                }),
              )
          ],
        ),
      ),
    );
  }
}
