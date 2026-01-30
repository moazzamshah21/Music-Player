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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBackground,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          backgroundColor: AppColors.navBackground,
          selectedItemColor: AppColors.navActive,
          unselectedItemColor: AppColors.navInactive,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Library',
            ),
          ],
          ),
        ),
      ),
    );
  }
}
