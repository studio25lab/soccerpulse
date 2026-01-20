import 'package:flutter/material.dart';
import 'package:soccer_pulse/services/user_preferences_service.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  late UserPreferencesService _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await UserPreferencesService.getInstance();
    setState(() => _ready = true);
  }

  Future<void> _selectTeam(int teamId) async {
    await _prefs.setSelectedTeamId(teamId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Placeholder: elenco team statico
    final teams = const [
      {'id': 489, 'name': 'Juventus'},
      {'id': 492, 'name': 'Milan'},
      {'id': 505, 'name': 'Inter'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona Squadra')),
      body: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, i) {
          final t = teams[i];
          return ListTile(
            title: Text('${t['name']}'),
            onTap: () => _selectTeam(t['id'] as int),
          );
        },
      ),
    );
  }
}
