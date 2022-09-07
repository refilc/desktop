import 'package:animations/animations.dart';
import 'package:filcnaplo/api/providers/database_provider.dart';
import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/icons/filc_icons.dart';
import 'package:filcnaplo/models/settings.dart';
import 'package:filcnaplo/utils/color.dart';
import 'package:filcnaplo_desktop_ui/common/panel_button.dart';
import 'package:filcnaplo_desktop_ui/common/profile_image.dart';
import 'package:filcnaplo_desktop_ui/screens/navigation/sidebar_action.dart';
import 'package:filcnaplo_desktop_ui/screens/settings/settings_screen.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';
import 'package:filcnaplo_kreta_api/providers/absence_provider.dart';
import 'package:filcnaplo_kreta_api/providers/event_provider.dart';
import 'package:filcnaplo_kreta_api/providers/exam_provider.dart';
import 'package:filcnaplo_kreta_api/providers/grade_provider.dart';
import 'package:filcnaplo_kreta_api/providers/homework_provider.dart';
import 'package:filcnaplo_kreta_api/providers/message_provider.dart';
import 'package:filcnaplo_kreta_api/providers/note_provider.dart';
import 'package:filcnaplo_kreta_api/providers/timetable_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:filcnaplo/theme/colors/colors.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({Key? key, required this.navigator, required this.onRouteChange, this.selected = "home"}) : super(key: key);

  final NavigatorState navigator;
  final String selected;
  final Function(String) onRouteChange;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late UserProvider user;
  late SettingsProvider settings;
  late String firstName;

  String topNav = "";
  bool expandAccount = false;

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserProvider>(context, listen: false);
  }

  Future<void> restore() => Future.wait([
        Provider.of<GradeProvider>(context, listen: false).restore(),
        Provider.of<TimetableProvider>(context, listen: false).restore(),
        Provider.of<ExamProvider>(context, listen: false).restore(),
        Provider.of<HomeworkProvider>(context, listen: false).restore(),
        Provider.of<MessageProvider>(context, listen: false).restore(),
        Provider.of<NoteProvider>(context, listen: false).restore(),
        Provider.of<EventProvider>(context, listen: false).restore(),
        Provider.of<AbsenceProvider>(context, listen: false).restore(),
        Provider.of<KretaClient>(context, listen: false).refreshLogin(),
      ]);

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);

    List<String> nameParts = user.name?.split(" ") ?? ["?"];
    if (!settings.presentationMode) {
      firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];
    } else {
      firstName = "Béla";
    }

    List<Widget> pageWidgets = [
      SidebarAction(
        title: const Text("Home"),
        icon: const Icon(FilcIcons.home),
        selected: widget.selected == "home",
        onTap: () {
          widget.navigator.pushReplacementNamed("home");
          widget.onRouteChange("home");
        },
      ),
      SidebarAction(
        title: const Text("Grades"),
        icon: const Icon(FeatherIcons.bookmark),
        selected: widget.selected == "grades",
        onTap: () {
          widget.navigator.pushReplacementNamed("grades");
          widget.onRouteChange("grades");
        },
      ),
      SidebarAction(
        title: const Text("Timetable"),
        icon: const Icon(FeatherIcons.calendar),
        selected: widget.selected == "timetable",
        onTap: () {
          widget.navigator.pushReplacementNamed("timetable");
          widget.onRouteChange("timetable");
        },
      ),
      SidebarAction(
        title: const Text("Messages"),
        icon: const Icon(FeatherIcons.messageSquare),
        selected: widget.selected == "messages",
        onTap: () {
          widget.navigator.pushReplacementNamed("messages");
          widget.onRouteChange("messages");
        },
      ),
      SidebarAction(
        title: const Text("Absences"),
        icon: const Icon(FeatherIcons.clock),
        selected: widget.selected == "absences",
        onTap: () {
          widget.navigator.pushReplacementNamed("absences");
          widget.onRouteChange("absences");
        },
      ),
    ];

    List<Widget> bottomActions = [
      SidebarAction(
        title: const Text("Settings"),
        selected: true,
        icon: const Icon(FeatherIcons.settings),
        onTap: () {
          if (topNav != "settings") {
            widget.navigator.push(CupertinoPageRoute(builder: (context) => const SettingsScreen())).then((value) => topNav = "");
            topNav = "settings";
          }
        },
      ),
    ];

    List<Widget> accountWidgets = [
      // Account settings
      PanelButton(
        onPressed: () {
          Navigator.of(context).pushNamed("login_back");
        },
        title: const Text("Add User"),
        leading: const Icon(FeatherIcons.userPlus),
      ),
      PanelButton(
        onPressed: () async {
          String? userId = user.id;
          if (userId == null) return;

          // Delete User
          user.removeUser(userId);
          await Provider.of<DatabaseProvider>(context, listen: false).store.removeUser(userId);

          // If no other Users left, go back to LoginScreen
          if (user.getUsers().isNotEmpty) {
            user.setUser(user.getUsers().first.id);
            restore().then((_) => user.setUser(user.getUsers().first.id));
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil("login", (_) => false);
          }
        },
        title: const Text("Log Out"),
        leading: Icon(FeatherIcons.logOut, color: AppColors.of(context).red),
      ),
    ];

    return SizedBox(
      height: double.infinity,
      width: 250.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0, top: 18.0, bottom: 24.0, right: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ProfileImage(
                    name: firstName,
                    radius: 18.0,
                    backgroundColor:
                        !settings.presentationMode ? ColorUtils.stringToColor(user.name ?? "?") : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    firstName,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PageTransitionSwitcher(
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return FadeThroughTransition(
                      fillColor: Colors.transparent,
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                  child: IconButton(
                    key: Key(expandAccount ? "accounts" : "pages"),
                    icon: Icon(expandAccount ? FeatherIcons.chevronDown : FeatherIcons.chevronRight),
                    padding: EdgeInsets.zero,
                    splashRadius: 20.0,
                    onPressed: () {
                      setState(() {
                        expandAccount = !expandAccount;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Pages
          Expanded(
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return SharedAxisTransition(
                  fillColor: Colors.transparent,
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  child: child,
                );
              },
              child: !expandAccount
                  ? Column(
                      key: const Key("pages"),
                      children: pageWidgets,
                    )
                  : Column(
                      key: const Key("accounts"),
                      children: accountWidgets,
                    ),
            ),
          ),

          const Spacer(),

          // Settings
          ...bottomActions,

          // Bottom padding
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
