import 'package:flutter/material.dart';
import 'package:despair/register_page.dart';
import 'package:despair/login_page.dart';
import 'package:despair/loading_page.dart';
import 'package:despair/forgot_password_page.dart';
import 'package:despair/validate_page.dart';
import 'package:despair/websocket_client.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(new App());

class App extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new WebsocketClient(
        child: new MaterialApp(
          title: "Skillbox",
          theme: new ThemeData(
            brightness: Brightness.dark,
          ),
          routes: {
            '/login': (context) => new LoginPage(),
            '/registrate': (context) => new RegisterPage(),
            '/loading': (context) => new LoadingPage(),
            '/forgotPassword': (context) => new ForgotPasswordPage(),
            '/validate': (context) => new ValidatePage(),
          },
          home: new RegisterPage(),
          debugShowCheckedModeBanner: false,
        ),
    );
  }
}

enum APP_STATE {
  INITIAL,
  FIRST_CONNECTION_FAILED,
  FIRST_CONNECTION_SUCCESS,
  AUTO_LOGIN_SUCCESS,
  AUTO_LOGIN_FAILED
}

class FirstPage extends StatelessWidget {
  const FirstPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder(
            stream: this._preload(context),
            initialData: APP_STATE.INITIAL,
            builder: (context, snapshot) {
              switch (snapshot.data) {
                case APP_STATE.FIRST_CONNECTION_FAILED:
                  return Scaffold(
                      body: Center(
                          child: Column(
                            children: <Widget>[
                              Text('We were unable to connect to GeoPoint server'),
                              FlatButton(
                                child: Text('OK'),
                                onPressed: () {
                                  //exit(0);
                                },
                              )
                            ],
                          )));
                case APP_STATE.FIRST_CONNECTION_SUCCESS:
                  return Scaffold(
                      body: Center(child: Text('Trying to log in...')));
                case APP_STATE.AUTO_LOGIN_FAILED:
                  Future.delayed(Duration(seconds: 2)).then(
                          (_) => Navigator.pushReplacementNamed(context, '/registrate'));
                  return Scaffold(
                      body: Center(
                          child: Text(
                              'We were unable to log in automatically, redirecting to Login page...')));
                case APP_STATE.AUTO_LOGIN_SUCCESS:
                  Future.delayed(Duration(seconds: 0)).then(
                          (_) => Navigator.pushReplacementNamed(context, '/map'));
                  break;
                default:
                  return Center(child: CircularProgressIndicator());
              }
              return Center(child: CircularProgressIndicator());
            }));
  }

  Stream<APP_STATE> _preload(BuildContext context) async* {
    yield* WebsocketClient.of(context)
        .establishGuestSession()
        .then((bool status) {
      return status
          ? APP_STATE.FIRST_CONNECTION_SUCCESS
          : APP_STATE.FIRST_CONNECTION_FAILED;
    }).asStream();

    yield* WebsocketClient.of(context).tryToAuth().then((bool status) {
      return status
          ? APP_STATE.AUTO_LOGIN_SUCCESS
          : APP_STATE.AUTO_LOGIN_FAILED;
    }).asStream();
  }
}

