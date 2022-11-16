import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _userIdTEC = TextEditingController();
  final _passwordTEC = TextEditingController();

  @override
  void dispose() {
    _userIdTEC.dispose();
    _passwordTEC.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // Initially password is obscure
  bool _obscureText = true;

  String? _password;

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> LoginProcess(userId, pass) async {
    // try {
    final SharedPreferences prefs = await _prefs;
    const url = 'https://synergicportal.in/claim/index.php/api';

    var map = new Map<String, dynamic>();
    map['user_id'] = userId;
    map['password'] = pass;
    final response = await http.post(Uri.parse(url + '/login'), body: map);
    // print(response.body);
    var data = jsonDecode(response.body);
    if (data['suc'] > 0) {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
// set value
      // print(data['msg']['emp_no']);
      await prefs.setString('empName', data['msg']['emp_name']);
      await prefs.setString('empNo', data['msg']['emp_no']);
      await prefs.setString('userType', data['msg']['user_type']);
      await prefs.setString('userId', data['msg']['user_id']);
      await prefs.setString('userStatue', data['msg']['user_status']);

      // Navigator.push(context,
      //     MaterialPageRoute(builder: (BuildContext context) {
      //   return const Dashboard();
      // }));

      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (BuildContext context) {
        return const Dashboard(docKey: 0);
      }), (route) => false);
    } else {
      var msg = data['msg'];
      var snackBar = SnackBar(
        content: Text(msg),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    // print(data['msg']['emp_name']);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // print(prefs.getString('userType'));

    // if (response.statusCode == 201) {
    //   // If the server did return a 201 CREATED response,
    //   // then parse the JSON.
    //   return Album.fromJson(jsonDecode(response.body));
    // } else {
    //   // If the server did not return a 201 CREATED response,
    //   // then throw an exception.
    //   throw Exception('Failed to create album.');
    // }

    // } catch (e) {
    //   print(e);
    // }
    // http.post('https://synergicportal.in/claim/index.php/api')
    // print(user_id);
    // print(pass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/back.png'), fit: BoxFit.fill)),
              child: Stack(children: [
                Positioned(
                  width: 80,
                  height: 50,
                  top: 50,
                  left: 30,
                  child: Container(
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/logo.png'))),
                  ),
                ),
                Positioned.fill(
                    top: 180,
                    child: Column(
                      children: const [
                        SizedBox(
                          child: Text(
                            "Welcome to STAMS",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          child: Text(
                            "Synergic tour & attendance management system",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ))
              ]),
            ),
            Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(children: [
                    const SizedBox(
                      height: 20.0,
                    ),
                    const Text(
                      'Login',
                      style: TextStyle(
                          color: Color.fromRGBO(62, 43, 100, 1),
                          fontSize: 40,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          letterSpacing: 6.0),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    TextFormField(
                      controller: _userIdTEC,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Employee Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.account_circle,
                            color: Color.fromRGBO(62, 43, 100, 1),
                          )),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter Your Employee Code";
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    TextFormField(
                      obscureText: _obscureText,
                      controller: _passwordTEC,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color.fromRGBO(62, 43, 100, 1),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility_rounded,
                              color: const Color.fromRGBO(62, 43, 100, 1),
                            ),
                          )
                          // Icon(
                          //   Icons.lock_outline,
                          //   color: Color.fromRGBO(62, 43, 100, 1),
                          // )
                          ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Supply Your Password";
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // if (await Vibration.hasAmplitudeControl() != null) {
                        //   Vibration.vibrate();
                        // }
                        if (formKey.currentState!.validate()) {
                          // const snackBar = SnackBar(
                          //   content: Text('Submitting Form!'),
                          // );
                          // _scaffoldKey.currentState!.showSnackBar(snackBar);
                          var _userId = _userIdTEC.text;
                          var _pass = _passwordTEC.text;
                          LoginProcess(_userId, _pass);
                        }
                      },
                      // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
                      style: ElevatedButton.styleFrom(
                          primary: const Color.fromARGB(255, 90, 66, 138),
                          elevation: 12.0,
                          textStyle: const TextStyle(color: Colors.white),
                          minimumSize: const Size(150, 40)),
                      child: const Text('Login'),
                    )
                  ]),
                ))
          ],
        ),
      ),
    );
  }
}
