import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/theme_provider.dart';
import '../services/metadata_scanner.dart';
import '../database/database_helper.dart';
import '../widgets/neumorphic_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onImportComplete;

  const SettingsScreen({super.key, required this.onImportComplete});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _gaplessPlayback = true;
  bool _replayGain = true;
  bool _crossfade = false;

  Future<void> _importLocalFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'flac', 'aac', 'm4a', 'ogg', 'wav', 'opus'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        int imported = 0;
        for (var file in result.files) {
          if (file.path != null) {
            final song = await MetadataScanner.scanFile(file.path!);
            if (song != null) {
              await DatabaseHelper.instance.insertOrUpdateSong(song);
              imported++;
            }
          }
        }
        widget.onImportComplete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported $imported tracks!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, 'Appearance & Theme'),
            const SizedBox(height: 12),
            NeumorphicCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text('White Neumorphism (Default)', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Clean white minimal interface with soft shadows', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    value: 'white_neumorphism',
                    groupValue: theme.themeMode,
                    activeColor: theme.accentColor,
                    onChanged: (val) => theme.setThemeMode(val!),
                  ),
                  const Divider(),
                  RadioListTile<String>(
                    title: Text('Dark Neumorphism', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Sleek dark theme with soft depth controls', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    value: 'dark_neumorphism',
                    groupValue: theme.themeMode,
                    activeColor: theme.accentColor,
                    onChanged: (val) => theme.setThemeMode(val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionHeader(theme, 'Audio Engine Settings'),
            const SizedBox(height: 12),
            NeumorphicCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Gapless Playback', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Seamless track transitions', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    value: _gaplessPlayback,
                    activeColor: theme.accentColor,
                    onChanged: (val) => setState(() => _gaplessPlayback = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Replay Gain', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Normalize volume across tracks', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    value: _replayGain,
                    activeColor: theme.accentColor,
                    onChanged: (val) => setState(() => _replayGain = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Crossfade Transitions', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Smoothly overlap songs', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    value: _crossfade,
                    activeColor: theme.accentColor,
                    onChanged: (val) => setState(() => _crossfade = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionHeader(theme, 'Library & Local Storage'),
            const SizedBox(height: 12),
            NeumorphicCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(LucideIcons.folderPlus, color: theme.accentColor),
                    title: Text('Import Local Music', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Scan MP3, FLAC, AAC, WAV, OPUS, OGG files', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    onTap: _importLocalFiles,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(LucideIcons.refreshCw, color: theme.accentColor),
                    title: Text('Rescan Music Library', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('Reload metadata and album artwork', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                    onTap: () async {
                      widget.onImportComplete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Library rescan triggered!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeProvider theme, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor, letterSpacing: 0.2),
    );
  }
}
