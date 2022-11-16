import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String endPoint = 'https://synergicportal.in/claim/index.php/api';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  var userDtls;
  String? empName;
  String? empDesig;
  String? empSector;
  String? empCode;

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   getUserDtls();
  //   // GetTourData();
  // }

  Future<void> getUserDtls() async {
    final SharedPreferences prefs = await _prefs;
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    final empNo = prefs.getString('empNo');

    final response = await http
        .get(Uri.parse(endPoint + '/emp_dtls?emp_code=' + empNo.toString()));
    var data = jsonDecode(response.body);
    print(data);
    if (data['suc'] > 0) {
      // setState(() {
      userDtls = data['msg'];
      empName = userDtls[0]['emp_name'];
      empDesig = userDtls[0]['designation'];
      empSector = userDtls[0]['sector'];
      empCode = empNo;
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    // getUserDtls();
    return Container(
        child: FutureBuilder(
            future: getUserDtls(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.deepPurpleAccent,
                  body: Container(
                      child: const SpinKitRotatingCircle(
                    color: Colors.white,
                    size: 80.0,
                  )),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.only(left: 16, top: 25, right: 16),
                  child: ListView(
                    children: [
                      const Text('Profile',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(
                        height: 50,
                      ),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 4,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor),
                                  boxShadow: [
                                    BoxShadow(
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.1))
                                  ],
                                  shape: BoxShape.circle,
                                  image: const DecorationImage(
                                      image:
                                          AssetImage('assets/img_avatar.png'),
                                      fit: BoxFit.cover)),
                            )
                          ],
                        ),
                      ),
                      Padding(
                          padding:
                              const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Name:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    letterSpacing: 3.0,
                                    fontSize: 20),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                '$empName',
                                style: const TextStyle(
                                    fontSize: 20.0,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              const Text(
                                'Designation:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    letterSpacing: 3.0,
                                    fontSize: 20),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                '$empDesig',
                                style: const TextStyle(
                                    fontSize: 20.0,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              const Text(
                                'Sector:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    letterSpacing: 3.0,
                                    fontSize: 20),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                '$empSector',
                                style: const TextStyle(
                                    fontSize: 20.0,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              const Text(
                                'Employee Code:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    letterSpacing: 3.0,
                                    fontSize: 20),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                '$empCode',
                                style: const TextStyle(
                                    fontSize: 20.0,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ))
                    ],
                  ),
                );
              }
            }));
  }
}
