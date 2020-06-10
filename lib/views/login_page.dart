import 'package:flutter/material.dart';
import 'package:push_chat/controller/user_controller.dart';
import 'package:push_chat/views/chat_page.dart';

class LoginPage extends StatelessWidget {
  static String tag = '/login';

  @override
  Widget build(BuildContext context) {
    var userController = UserController.of(context);

    // Login ja existe?
    userController.checkIsLoggedIn().then((user) {
      if (user != null) {
        Navigator.of(context).pushReplacementNamed(ChatPage.tag);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Push Chat App'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Fala login para começar',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 30),
            RaisedButton(
              onPressed: () async {
                await userController.signIn();

                if (userController.isLoggedIn()) {
                  Navigator.of(context).pushReplacementNamed(ChatPage.tag);
                }
              },
              child: Text(
                'Login com o Google',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                      color: Colors.white,
                    ),
              ),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
