import 'package:flutter/material.dart';
import 'websocket_client.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

final _registerFormKey = new GlobalKey<FormState>();

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _passController = TextEditingController();

    String _username;
    String _email;
    String _password;

    return new Scaffold(
      body: new Center(
        child: new Container(
          padding: new EdgeInsets.all(60.0),
          child: new SingleChildScrollView(
            child: new Form(
              key: _registerFormKey,
              child: new Column(
                children: <Widget>[
                  new Container(
                    child: new Text(
                      "SIGN UP",
                      textAlign: TextAlign.center,
                      style: new TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.04,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Times new roman',
                      ),
                    ),
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "Login"),
                    validator: (value) => value.length < 4 || value.length > 20
                        ? "Login is incorrect"
                        : null,
                    autovalidate: true,
                    onSaved: (String value) => _username = value,
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "E-mail"),
                    validator: validateEmail,
                    autovalidate: true,
                    onSaved: (String value) => _email = value,
                  ),
                  new TextFormField(
                    controller: _passController,
                    decoration: new InputDecoration(labelText: "Password"),
                    validator: (value) =>
                    value.length < 4 ? "Password too short" : null,
                    obscureText: true,
                    autovalidate: true,
                    onSaved: (String value) => _password = value,
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "Repeat password"),
                    validator: (value) => value != _passController.text
                        ? "Password do not match"
                        : null,
                    obscureText: true,
                    autovalidate: true,
                  ),
                  new Padding(
                    padding: new EdgeInsets.only(top: 20.0),
                  ),
                  new RaisedButton(
                    child: new Text(
                      "Register",
                      style: new TextStyle(
                        fontFamily: 'Times new roman',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (_registerFormKey.currentState.validate()) {
                        _registerFormKey.currentState.save();
                        WebsocketClient.of(context)
                          .attemptRegister(_username, sha256.convert(utf8.encode(_password)).toString(), _email)
                          .then(
                            (ServerResponse response) {
                              if (response.status) {
                                Navigator.of(context).pushNamed("/validate");
                              }
                              else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => new AlertDialog(
                                    title: new Text(
                                      "An error occured",
                                       style: new TextStyle(
                                         fontWeight: FontWeight.bold,
                                       ),
                                    ),
                                    content: new Text(response.code),
                                    actions: <Widget>[
                                      new FlatButton(
                                        child: new Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                        );
                      }
                    },
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
            new Text("Have account?"),
            new FlatButton(
              padding:
              EdgeInsets.only(left: 2.0, top: 0.0, right: 0.0, bottom: 0.0),
              child: new Text(
                "Sign in now",
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                //Navigator.of(context).pushNamed('/login');
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
String validateEmail(String value) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(value))
    return "Enter Valid Email";
  else
    return null;
}
