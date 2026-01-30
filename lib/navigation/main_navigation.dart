import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umarplayer/view/home.dart';
import 'package:umarplayer/view/search.dart';
import 'package:umarplayer/view/library.dart';
import 'package:umarplayer/view/player_screen.dart';
import 'package:umarplayer/widgets/mini_player.dart';
import 'package:umarplayer/providers/player_provider.dart';
import 'package:umarplayer/theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const Search(),
    const Library(),
  ];

  void _openPlayerScreen(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    if (playerProvider.currentItem != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          // Base background (all tabs)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.backgroundElevated,
                    AppColors.surface,
                  ],
                ),
              ),
            ),
          ),
          // Home tab only: warm gradient on top half
          if (_currentIndex == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.5,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.brandy.withOpacity(0.22),
                        AppColors.brandyDark.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          _pages[_currentIndex],
            Consumer<PlayerProvider>(
              builder: (context, playerProvider, _) {
                return playerProvider.currentItem != null
                    ? Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: MiniPlayer(
                          currentItem: playerProvider.currentItem,
                          isPlaying: playerProvider.isPlaying,
                          isLiked: playerProvider.isLiked,
                          isLoading: playerProvider.isLoading,
                          loadingMessage: playerProvider.loadingMessage,
                          onPlayPause: () => playerProvider.playPause(),
                          onTap: () => _openPlayerScreen(context),
                          onFavorite: () => playerProvider.toggleFavorite(),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navBackground.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.navActive,
                unselectedItemColor: AppColors.navInactive,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
