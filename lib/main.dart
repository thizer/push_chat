import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:push_chat/controller/user_controller.dart';
import 'package:push_chat/views/chat_page.dart';
import 'package:push_chat/views/login_page.dart';

void main() {
  runApp(
    UserController(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //
    //Remove this method to stop OneSignal Debugging
    // OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared.init(
      "SUA-CHAVE-ONE-SIGNAL-AQUI",
      iOSSettings: {
        OSiOSSettings.autoPrompt: false,
        OSiOSSettings.inAppLaunchUrl: false,
      },
    );
    OneSignal.shared.setInFocusDisplayType(OSNotificationDisplayType.notification);

    //
    // Ao criar a instancia (que deve acontecer apenas uma vez)
    // o sistema ja deve guardar o playerID do OneSignal
    OneSignal.shared.getPermissionSubscriptionState().then((status) {
      UserController.of(context).playerId = status.subscriptionStatus.userId;
    });

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: LoginPage.tag,
      routes: {
        LoginPage.tag: (context) => LoginPage(),
        ChatPage.tag: (context) => ChatPage(),
      },
    );
  }
}
