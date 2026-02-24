import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme_mode_provider.dart';
import '../providers/auth_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _editingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isDark = themeMode == ThemeMode.dark;
    final tileTitleColor = isDark ? null : const Color(0xFF2D2540);
    final tileSubtitleColor = isDark ? null : const Color(0xFF5C5470);
    final tileIconColor = isDark ? null : const Color(0xFF4D4563);
    final tileDividerColor = isDark ? null : const Color(0xFFD8D3E5);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _PressScale(
            child: Card(
              child: ListTileTheme(
                iconColor: tileIconColor,
                textColor: tileTitleColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_rounded),
                      title: const Text('Signed in as'),
                      subtitle: Text(
                        authState.userEmail ?? '-',
                        style: TextStyle(color: tileSubtitleColor),
                      ),
                    ),
                    Divider(height: 1, color: tileDividerColor),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Display name'),
                      subtitle: Text(
                        authState.userName?.trim().isNotEmpty == true
                            ? authState.userName!
                            : 'Not set',
                        style: TextStyle(color: tileSubtitleColor),
                      ),
                      trailing: IconButton(
                        icon: Icon(_editingName ? Icons.close_rounded : Icons.edit_rounded),
                        onPressed: () {
                          setState(() {
                            _editingName = !_editingName;
                            if (_editingName) {
                              _nameController.text = authState.userName ?? '';
                            }
                          });
                        },
                      ),
                    ),
                    if (_editingName) ...[
                      Divider(height: 1, color: tileDividerColor),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              autofocus: false,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: 'Enter your name',
                              ),
                              onSubmitted: (_) => _saveName(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingName = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _saveName,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTileTheme(
              iconColor: tileIconColor,
              textColor: tileTitleColor,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security_rounded),
                    title: const Text('Data & Privacy'),
                    subtitle: Text(
                      'Your data is stored per account',
                      style: TextStyle(color: tileSubtitleColor),
                    ),
                  ),
                  Divider(height: 1, color: tileDividerColor),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Appearance'),
                    subtitle: Text(
                      isDark ? 'Dark theme' : 'Light theme',
                      style: TextStyle(color: tileSubtitleColor),
                    ),
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (value) => themeNotifier.toggle(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PressScale(
            scaleDown: 0.975,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF7C45FF), Color(0xFF6139E8), Color(0xFF8E5CFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C45FF).withValues(
                      alpha: isDark ? 0.35 : 0.2,
                    ),
                    blurRadius: isDark ? 18 : 12,
                    offset: Offset(0, isDark ? 8 : 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => notifier.signOut(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18 / 1.1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveName() {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(authProvider.notifier);
    final ok = notifier.updateDisplayName(_nameController.text);
    if (!mounted) return;
    setState(() {
      _editingName = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Display name updated' : 'Could not update display name',
          ),
        ),
      );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.scaleDown = 0.985});

  final Widget child;
  final double scaleDown;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? widget.scaleDown : 1,
        child: widget.child,
      ),
    );
  }
}
