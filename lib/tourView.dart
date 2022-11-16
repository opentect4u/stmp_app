import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tour.dart';
import 'tourEntry.dart';

class TourView extends StatefulWidget {
  const TourView({Key? key}) : super(key: key);

  @override
  State<TourView> createState() => _TourViewState();
}

class _TourViewState extends State<TourView> {
  String endPoint = 'https://synergicportal.in/claim/index.php/api';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  var data;
  Future<void> getVisitList() async {
    final SharedPreferences prefs = await _prefs;
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    final empNo = prefs.getString('empNo');

    final response = await http.post(
        Uri.parse(endPoint + '/visit_mgmt_dtls?emp_code=' + empNo.toString()));
    var dt = jsonDecode(response.body.toString());
    // print(Uri.parse(endPoint + '/visit_mgmt_dtls?emp_no=' + empNo.toString()));
    if (dt['suc'] > 0) {
      data = dt['msg'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              child: FutureBuilder(
                  future: getVisitList(),
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
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                              onTap: () {
                                // print(data[index]['sl_no'].toString());
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return tourEntry(
                                      rowid: int.parse(data[index]['sl_no']));
                                }));
                              },
                              child: Card(
                                color: data[index]['in_out_flag'] == 'O'
                                    ? Colors.green[300]
                                    : Colors.white,
                                child: Column(
                                  children: [
                                    ReusableRow(
                                        title: 'Date',
                                        value:
                                            data[index]['visit_dt'].toString()),
                                    ReusableRow(
                                        title: 'Organization',
                                        value:
                                            data[index]['org_name'].toString()),
                                    ReusableRow(
                                        title: 'Person',
                                        value: data[index]['contact_person']
                                            .toString()),
                                  ],
                                ),
                              ));
                        },
                      );
                    }
                  }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return tourEntry(rowid: 0);
          }));
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReusableRow extends StatelessWidget {
  String title, value;
  ReusableRow({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value)],
      ),
    );
  }
}
