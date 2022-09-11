import 'package:filcnaplo/api/providers/news_provider.dart';
import 'package:filcnaplo/api/providers/sync.dart';
import 'package:filcnaplo/theme/observer.dart';
import 'package:filcnaplo_desktop_ui/screens/navigation/navigation_route.dart';
import 'package:filcnaplo_desktop_ui/screens/navigation/navigation_route_handler.dart';
import 'package:filcnaplo_desktop_ui/screens/navigation/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:filcnaplo/models/settings.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  static NavigationScreenState? of(BuildContext context) => context.findAncestorStateOfType<NavigationScreenState>();

  @override
  State<NavigationScreen> createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver {
  final _navigatorState = GlobalKey<NavigatorState>();
  late NavigationRoute selected;
  late SettingsProvider settings;
  late NewsProvider newsProvider;
  double topInset = 0.0;

  @override
  void initState() {
    super.initState();
    settings = Provider.of<SettingsProvider>(context, listen: false);
    selected = NavigationRoute();
    selected.index = 0;

    // add brightness observer
    WidgetsBinding.instance.addObserver(this);

    // set client User-Agent
    Provider.of<KretaClient>(context, listen: false).userAgent = settings.config.userAgent;

    // Get news
    newsProvider = Provider.of<NewsProvider>(context, listen: false);
    newsProvider.restore().then((value) => newsProvider.fetch());

    // Initial sync
    syncAll(context);

    () async {
      try {
        await Window.initialize();
      } catch (_) {}
      topInset = await Window.getTitlebarHeight();
      // Transparent sidebar
      await Window.setEffect(effect: WindowEffect.acrylic);
      await Window.enableFullSizeContentView();
      await Window.hideTitle();
      await Window.makeTitlebarTransparent();
    }();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (settings.theme == ThemeMode.system) {
      Brightness? brightness = WidgetsBinding.instance.window.platformBrightness;
      Provider.of<ThemeModeObserver>(context, listen: false).changeTheme(brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark);
    }
    super.didChangePlatformBrightness();
  }

  void setPage(String page) => setState(() => selected.name = page);

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsProvider>(context);
    newsProvider = Provider.of<NewsProvider>(context);

    // Show news
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newsProvider.show) {
        newsProvider.lock();
        // NewsView.show(newsProvider.news[newsProvider.state], context: context).then((value) => newsProvider.release());
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          if (_navigatorState.currentState != null)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.5),
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Sidebar(
                  navigator: _navigatorState.currentState!,
                  selected: selected.name,
                  onRouteChange: (name) => setPage(name),
                ),
              ),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.only(top: topInset),
                ),
                child: Navigator(
                  key: _navigatorState,
                  initialRoute: selected.name,
                  onGenerateRoute: (settings) => navigationRouteHandler(settings),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
