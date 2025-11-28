// =============================================================================
// FLUTTER FRONTEND – CPU Scheduling Comparator UI
// =============================================================================
// This UI interacts with the Python backend API at http://localhost:5000/calculate
// It allows users to:
//  - Add/remove processes
//  - Enter Arrival Time (AT) and Burst Time (BT)
//  - Enter Quantum time for Round Robin
//  - View FCFS and RR results
//  - Display Gantt charts
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(const SchedulerApp());


// =============================================================================
// APP ROOT (MaterialApp Setup)
// =============================================================================
class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Allows mouse dragging for desktop apps
      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),

      title: 'CPU Scheduling Comparator',
      debugShowCheckedModeBanner: false,

      // Global Theme
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),

      // Home page
      home: const HomePage(),
    );
  }
}



// =============================================================================
// HOME PAGE (Main application screen)
// =============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  // Predefined colors for Gantt chart blocks
  static const colors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFF8B5CF6), // Purple
  ];

  // Idle color for CPU idle blocks
  static const idleColor = Color(0xFFCBD5E1);

  // Initial list of processes
  List<Map<String, dynamic>> processes = [
    {'id': 'P1', 'at': 0, 'bt': 4},
    {'id': 'P2', 'at': 1, 'bt': 3},
  ];

  int pCount = 2;           // Auto-increment process counter
  int quantum = 2;          // Default quantum for Round Robin
  Map<String, dynamic>? result;  // Stores backend response
  bool loading = false;          // Loading state for API call
  String? error;                 // Error message



  // ---------------------------------------------------------------------------
  // Add new process row
  // ---------------------------------------------------------------------------
  void addProcess() {
    setState(() {
      pCount++;
      processes.add({'id': 'P$pCount', 'at': 0, 'bt': 1});
    });
  }

  // ---------------------------------------------------------------------------
  // Remove process at index `i`
  // Prevent removing the last process
  // ---------------------------------------------------------------------------
  void removeProcess(int i) {
    if (processes.length > 1) {
      setState(() => processes.removeAt(i));
    }
  }

  // ---------------------------------------------------------------------------
  // API CALL to Python backend
  // Sends JSON: { processes: [...], quantum: Q }
  // Receives JSON containing FCFS & RR results + Gantt charts
  // ---------------------------------------------------------------------------
  Future<void> calculate() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'processes': processes,
          'quantum': quantum,
        }),
      );

      // Success
      if (response.statusCode == 200) {
        setState(() => result = jsonDecode(response.body));
      } else {
        setState(() => error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      // If server is not running
      setState(() => error = 'Cannot connect to server. Is Python running?');
    }

    setState(() => loading = false);
  }



  // =============================================================================
  // BUILD UI
  // =============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // ------------------------- Title -------------------------
                const Text(
                  'CPU Scheduling Comparator',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 20),

                // ------------------------- Input Section -------------------------
                _buildCard(_buildInputSection()),
                const SizedBox(height: 20),

                // ------------------------- Any Errors -------------------------
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16)),
                  ),

                // ------------------------- Results Section -------------------------
                if (result != null) _buildResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // Card Container Helper
  // Creates a white card with shadow and padding
  // ---------------------------------------------------------------------------
  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Section title helper
  // ---------------------------------------------------------------------------
  Widget _buildSectionTitle(String text) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }



  // =============================================================================
  // INPUT SECTION (Processes Table + Buttons)
  // =============================================================================
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. Configuration'),
        const SizedBox(height: 10),

        // ------------------------- Process Table -------------------------
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(
                  label: Text('Process ID',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Arrival Time',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Burst Time',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Action',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],

            // Table rows
            rows: List.generate(processes.length, (i) {
              return DataRow(cells: [
                DataCell(Text(processes[i]['id'])),

                // Arrival Time input
                DataCell(_buildNumberInput(
                  processes[i]['at'],
                  (v) => setState(() => processes[i]['at'] = v),
                )),

                // Burst Time input
                DataCell(_buildNumberInput(
                  processes[i]['bt'],
                  (v) => setState(() => processes[i]['bt'] = v),
                  min: 1,
                )),

                // Delete button
                DataCell(IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => removeProcess(i),
                )),
              ]);
            }),
          ),
        ),

        const SizedBox(height: 15),

        // ------------------------- Controls (Add, Quantum, Calculate) -------------------------
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Add Process Button
            ElevatedButton.icon(
              onPressed: addProcess,
              icon: const Icon(Icons.add),
              label: const Text('Add Process'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),

            // Quantum input field
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Time Quantum: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller:
                        TextEditingController(text: quantum.toString()),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    onChanged: (v) => quantum = int.tryParse(v) ?? 2,
                  ),
                ),
              ],
            ),

            // Calculate Button
            ElevatedButton.icon(
              onPressed: loading ? null : calculate,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(loading ? 'Calculating...' : 'Calculate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }



  // =============================================================================
  // Numeric Input Field Builder
  // =============================================================================
  Widget _buildNumberInput(int value, Function(int) onChanged,
      {int min = 0}) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: TextEditingController(text: value.toString()),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onChanged: (v) {
          int parsed = int.tryParse(v) ?? min;
          if (parsed < min) parsed = min;
          onChanged(parsed);
        },
      ),
    );
  }



  // =============================================================================
  // Results Section (FCFS + RR side-by-side)
  // =============================================================================
  Widget _buildResults() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screen → Side-by-side
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(_buildAlgoCard(
                  'First Come First Serve (FCFS)', result!['fcfs'])),
              const SizedBox(width: 20),
              Expanded(_buildAlgoCard(
                  'Round Robin (Q=$quantum)', result!['rr'])),
            ],
          );
        }

        // Narrow screen → Stacked
        return Column(
          children: [
            _buildAlgoCard(
                'First Come First Serve (FCFS)', result!['fcfs']),
            const SizedBox(height: 20),
            _buildAlgoCard('Round Robin (Q=$quantum)', result!['rr']),
          ],
        );
      },
    );
  }



  // =============================================================================
  // Algorithm Result Card
  // Shows Table + Averages + Gantt Chart
  // =============================================================================
  Widget _buildAlgoCard(String title, Map<String, dynamic> data) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 10),

          // ------------------------- Results Table -------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(Colors.grey.shade100),
              columnSpacing: 15,
              columns: ['Proc', 'AT', 'BT', 'CT', 'TAT', 'WT', 'RT']
                  .map((h) => DataColumn(
                        label: Text(h,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ))
                  .toList(),

              // Fill table rows
              rows: (data['results'] as List).map<DataRow>((r) {
                return DataRow(cells: [
                  DataCell(Text(r['id'].toString())),
                  DataCell(Text(r['at'].toString())),
                  DataCell(Text(r['bt'].toString())),
                  DataCell(Text(r['ct'].toString())),
                  DataCell(Text(r['tat'].toString())),
                  DataCell(Text(r['wt'].toString())),
                  DataCell(Text(r['rt'].toString())),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------- Averages -------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Averages:  TAT: ${data['metrics']['avg_tat']}  |  '
              'WT: ${data['metrics']['avg_wt']}  |  RT: ${data['metrics']['avg_rt']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 15),

          // ------------------------- Gantt Chart -------------------------
          const Text('Gantt Chart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _buildGanttChart(data['gantt']),
        ],
      ),
    );
  }



  // =============================================================================
  // GANTT CHART WIDGET
  // Displays blocks (processes or idle periods) horizontally
  // =============================================================================
  Widget _buildGanttChart(List gantt) {
    const double minBlockWidth = 60.0; // Ensures text fits inside block
    const double pixelsPerUnit = 40.0; // Scale for width calculation

    return Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),

      // Horizontal scroll because Gantt charts can be long
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: gantt.map<Widget>((g) {
            // Duration = end - start
            int duration = g['end'] - g['start'];

            // Convert duration to pixel width
            double width =
                (duration * pixelsPerUnit).clamp(minBlockWidth, double.infinity);

            bool isIdle = g['idle'] == true;
            Color color = isIdle
                ? idleColor
                : colors[(g['idx'] ?? 0) % 5]; // Pick color by index

            return Column(
              children: [
                // ----------------------- Gantt Block -----------------------
                Container(
                  width: width,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    border: const Border(
                      right: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),

                  // Process ID label inside block
                  child: Center(
                    child: Text(
                      g['id'],
                      style: TextStyle(
                        color: isIdle ? Colors.black54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // ----------------------- Time Markers -----------------------
                Container(
                  width: width,
                  height: 25,
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${g['start']}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${g['end']}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF64748B)),
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
}
