import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../features/calendar/presentation/calendar_page.dart';
import '../features/currency/presentation/currency_home_page.dart';
import '../features/notes/presentation/notes_page.dart';

/// App dashboard: a bento-style grid of mini-apps. Add a new app by appending
/// to [_apps] — its tile size comes from [_MiniApp.cross] (columns of 4) and
/// [_MiniApp.height] (fixed pixel height).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apps = _apps(scheme);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Super App',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final app in apps)
                    StaggeredGridTile.extent(
                      crossAxisCellCount: app.cross,
                      mainAxisExtent: app.height,
                      child: _BentoTile(app: app),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<_MiniApp> _apps(ColorScheme scheme) => [
        _MiniApp(
          title: 'Calendar',
          subtitle: 'Tasks, events & call alerts',
          icon: Icons.calendar_month,
          route: CalendarPage.route,
          colors: [scheme.primary, scheme.tertiary],
          cross: 2,
          height: 278,
        ),
        _MiniApp(
          title: 'Currency',
          subtitle: 'Live & offline rates',
          icon: Icons.currency_exchange,
          route: CurrencyHomePage.route,
          colors: [scheme.secondary, scheme.primary],
          cross: 2,
          height: 132,
        ),
        _MiniApp(
          title: 'Notes',
          subtitle: 'Quick thoughts & lists',
          icon: Icons.sticky_note_2,
          route: NotesPage.route,
          colors: [scheme.tertiary, scheme.secondary],
          cross: 2,
          height: 132,
        ),
        _MiniApp(
          title: 'More soon',
          subtitle: 'New mini-apps land here',
          icon: Icons.auto_awesome,
          colors: [
            scheme.surfaceContainerHighest,
            scheme.surfaceContainerHigh,
          ],
          muted: true,
          cross: 2,
          height: 132,
        ),
      ];
}

class _MiniApp {
  const _MiniApp({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.cross,
    required this.height,
    this.route,
    this.muted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  /// Number of grid columns (of 4) this tile spans.
  final int cross;

  /// Fixed tile height in logical pixels (so content never overflows).
  final double height;
  final String? route;
  final bool muted;
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({required this.app});

  final _MiniApp app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = app.muted ? scheme.onSurfaceVariant : scheme.onPrimary;
    final enabled = app.route != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => Navigator.pushNamed(context, app.route!)
              : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: app.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Faint oversized watermark icon.
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Icon(
                    app.icon,
                    size: 96,
                    color: fg.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(app.icon, color: fg, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        app.title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
