import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

final _loginFormKey = new GlobalKey<FormState>();

class LoginPage extends StatelessWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String _login;
    String _password;

    return new Scaffold(
      body: new Center(
        child: new Container(
          padding: new EdgeInsets.all(60.0),
          child: new SingleChildScrollView(
            child: new Form(
              key: _loginFormKey,
              child: new Column(
                children: <Widget>[
                  new Text(
                    "SIGN IN",
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.04,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Times new roman',
                    ),
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "Login"),
                    validator: (value) => value.length < 4 || value.length > 20
                        ? "Login is incorrect"
                        : null,
                    initialValue: _login ?? "",
                    autovalidate: true,
                    onSaved: (String value) => _login = value,
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "Password"),
                    validator: (value) =>
                        value.length <= 4 ? "Password too short" : null,
                    autovalidate: true,
                    obscureText: true,
                    onSaved: (String value) => _password =
                        sha256.convert(utf8.encode(value)).toString(),
                  ),
                  new Padding(
                    padding: EdgeInsets.only(top: 20.0),
                  ),
                  new RaisedButton(
                    child: new Text(
                      "Login",
                      style: new TextStyle(
                        fontFamily: 'Times new roman',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => {},
                  ),
                  new Padding(
                    padding: EdgeInsets.only(top: 10.0),
                  ),
                  new FlatButton(
                    child: new Text(
                      "Forgot password?",
                      style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    splashColor: Colors.white,
                    highlightColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: new BottomAppBar(
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text("No account?"),
            new FlatButton(
              padding:
                  EdgeInsets.only(left: 2.0, top: 0.0, right: 0.0, bottom: 0.0),
              child: new Text(
                "Sign up now",
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                //Navigator.of(context).pushNamed('/registrate');
                //Navigator.of(context).pop();
              },
              splashColor: Colors.white,
              highlightColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
