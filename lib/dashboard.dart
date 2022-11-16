import 'package:flutter/material.dart';
import 'attendance.dart';
import 'login.dart';
import 'profile.dart';
import 'tourView.dart';
// import 'package:geolocator_android/geolocator_android.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key, required this.docKey}) : super(key: key);
  final int docKey;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  final screens = [const Attendance(), const TourView(), const Profile()];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _currentIndex = widget.docKey.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        selectedItemColor: Colors.deepPurpleAccent,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              tooltip: 'Home',
              label: 'Home',
              backgroundColor: Colors.deepPurple),
          BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              tooltip: 'Tour',
              label: 'Tour',
              backgroundColor: Colors.deepPurple),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              tooltip: 'Profile',
              label: 'Profile',
              backgroundColor: Colors.deepPurple)
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
