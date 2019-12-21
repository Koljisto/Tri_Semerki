import 'package:despair/websocket_client.dart';
import 'package:flutter/material.dart';

var _validateFormKey = new GlobalKey<FormState>();

class ValidatePage extends StatelessWidget {
  const ValidatePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String _key;
    return new Scaffold(
      body: new Center(
        child: new Container(
          padding: new EdgeInsets.all(60.0),
          child: new SingleChildScrollView(
            child: new Form(
              key: _validateFormKey,
              child: new Column(
                children: <Widget>[
                  new Text(
                    "We sent you an email to verify your Email address.",
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                      fontFamily: 'Times new roman',
                    ),
                  ),
                  new TextFormField(
                    decoration: new InputDecoration(labelText: "Enter a key"),
                    onSaved: (String value) => _key = value,
                  ),
                  new Padding(padding: EdgeInsets.all(5.0)),
                  new RaisedButton(
                    child: new Text(
                      "Confirm",
                    ),
                    onPressed: () {
                      if (_validateFormKey.currentState.validate()) {
                        _validateFormKey.currentState.save();
                        WebsocketClient.of(context)
                            .attemptActivation(_key)
                            .then((ServerResponse response) {
                              if (response.status) {
                                Navigator.of(context)..pop()..pop();
                              }
                              else {
                                return;
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
    );
  }
}
