// FLUTTER UI FOR CPU SCHEDULING (FCFS + RR)

import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(SchedulerApp());

class SchedulerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      title: "Scheduling Algorithms",
      debugShowCheckedModeBanner: false,
      home: SchedulerScreen(),
    );
  }
}

class SchedulerScreen extends StatefulWidget {
  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {

  // Initial sample process list
  List<Map<String, String>> processes = [
    {"id": "P1", "at": "0", "bt": "1"},
    {"id": "P2", "at": "1", "bt": "2"},
  ];

  // Time Quantum input
  TextEditingController quantumCtrl = TextEditingController(text: "2");

  // Results from server
  Map<String, dynamic>? fcfsResult;
  Map<String, dynamic>? rrResult;

  // Add new process row
  void addProcess() {
    int n = processes.length + 1;
    processes.add({"id": "P$n", "at": "0", "bt": "1"});
    setState(() {});
  }

  // Remove a process row
  void removeProcess(int index) {
    if (processes.length > 1) {
      processes.removeAt(index);
      setState(() {});
    }
  }

  // Send data to Flask Backend
  Future<void> calculate() async {
    final url = Uri.parse("http://127.0.0.1:5000/calculate");

    final body = {
      "processes": processes
          .map((p) => {
                "id": p["id"],
                "at": int.tryParse(p["at"] ?? "0") ?? 0,
                "bt": int.tryParse(p["bt"] ?? "1") ?? 1,
              })
          .toList(),
      "quantum": int.parse(quantumCtrl.text)
    };

    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    setState(() {
      fcfsResult = data["fcfs"];
      rrResult = data["rr"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8fafc),

      appBar: AppBar(
        title: Text("CPU Scheduling FCFS & RR",style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xff2563eb),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            // INPUT CARD
            Container(
              padding: EdgeInsets.all(20),
              decoration: _cardStyle(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Enter Processes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10),

                  // Process Input Table
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      TableRow(children: [
                        _header("ID"),
                        _header("AT"),
                        _header("BT"),
                        _header("Action"),
                      ])
                    ] +
                        processes.map((p) {
                          int index = processes.indexOf(p);

                          return TableRow(children: [
                            _cell(p["id"]!),

                            _inputCell(p, "at"),
                            _inputCell(p, "bt"),

                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeProcess(index),
                            ),
                          ]);
                        }).toList(),
                  ),

                  SizedBox(height: 10),

                  // Add process, Time Quantum & Calculate button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: addProcess,
                        child: Text("Add Process",style: TextStyle(color: Colors.white)),
                      ),

                      Row(
                        children: [
                          Text(" Time Quantum: "),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: quantumCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff2563eb),
                            ),
                            onPressed: calculate,
                            child: Text("Calculate",style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 20),

            if (fcfsResult != null) _algoCard("FCFS", fcfsResult!),
            SizedBox(height: 20),
            if (rrResult != null) _algoCard("Round Robin", rrResult!),
          ],
        ),
      ),
    );
  }

  // REUSABLE UI WIDGETS
  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
      ],
    );
  }

  Widget _header(String text) =>
      Padding(padding: EdgeInsets.all(8), child: Text(text, textAlign: TextAlign.center));

  Widget _cell(String text) =>
      Padding(padding: EdgeInsets.all(8), child: Text(text, textAlign: TextAlign.center));

  Widget _inputCell(Map p, String key) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: TextField(
        controller: TextEditingController(text: p[key]),
        onChanged: (v) => p[key] = v,
        keyboardType: TextInputType.number,
      ),
    );
  }


  // Algorithm Output Card
  Widget _algoCard(String title, Map data) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),

          // Table of Metrics
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(children: [
                _header("ID"),
                _header("AT"),
                _header("BT"),
                _header("CT"),
                _header("TAT"),
                _header("WT"),
                _header("RT"),
              ])
            ] +
                data["results"].map<TableRow>((p) {
                  return TableRow(children: [
                    _cell(p["id"].toString()),
                    _cell(p["at"].toString()),
                    _cell(p["bt"].toString()),
                    _cell(p["ct"].toString()),
                    _cell(p["tat"].toString()),
                    _cell(p["wt"].toString()),
                    _cell(p["rt"].toString()),
                  ]);
                }).toList(),
          ),

          SizedBox(height: 10),

          // Averages
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Averages: TAT: ${data['metrics']['avg_tat']} | WT: ${data['metrics']['avg_wt']} | RT: ${data['metrics']['avg_rt']}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(height: 15),

          Text("Gantt Chart:", style: TextStyle(fontWeight: FontWeight.bold)),

          SizedBox(height: 10),

          // Gantt Chart
          _buildGanttChart(data["gantt"]),
        ],
      ),
    );
  }

  // Gantt Chart Widget
  Widget _buildGanttChart(List gantt) {
    const double pixelsPerUnit = 40.0;
    const double minBlockWidth = 60.0;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: gantt.map<Widget>((g) {
            int duration = g["end"] - g["start"];
            double width = (duration * pixelsPerUnit).clamp(minBlockWidth, double.infinity);

            bool isIdle = g["idle"] == true;
            Color color = isIdle ? Color(0xFFCBD5E1) : _getColor(g["idx"]);

            return Column(
              children: [
                Container(
                  width: width,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      g["id"],
                      style: TextStyle(
                        color: isIdle ? Colors.black54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: width,
                  height: 25,
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '${g["start"]}',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          '${g["end"]}',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColor(int? idx) {
    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFFEF4444), // Red
      Color(0xFF10B981), // Green
      Color(0xFFF59E0B), // Orange
      Color(0xFF8B5CF6), // Purple
    ];
    return colors[(idx ?? 0) % colors.length];
  }
}
