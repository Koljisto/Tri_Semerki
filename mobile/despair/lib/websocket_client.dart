import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

const String WEBSERVER_LOCATION = "10.0.2.2:8010";

class WebsocketClient extends InheritedWidget {
  final WebsocketService client = WebsocketService();

  WebsocketClient({Key key, @required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static WebsocketService of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(WebsocketClient)
    as WebsocketClient)
        .client as WebsocketService;
  }
}

class ServerResponse {
  int id;
  bool status;
  String code;
  dynamic data;

  ServerResponse(this.id, this.status, this.code, this.data);
  ServerResponse.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        status = json['status'] == 'success',
        code = json['code'] as String,
        data = json['data'];
}

class WebsocketService {
  IOWebSocketChannel _authorizedChannel;
  IOWebSocketChannel _guestChannel;

  int _id = 0;

  final StreamController<ServerResponse> serverBroadcast =
  StreamController.broadcast();

  final StreamController<ServerResponse> _responder =
  StreamController.broadcast();

  double _serverTimeOffset;

  double get serverTimeOffset {
    this._serverTimeOffset ??
        this
            ._sendMessage('get_time', authorized: false)
            .then((ServerResponse response) {
          this._serverTimeOffset = response.data as double;
          print(response.data);
        });
    return this._serverTimeOffset ?? 0;
  }

  String username;
  String email;

  Future<ServerResponse> attemptActivation(String key) async =>
      this._sendMessage('activate', data: {'key': key}, authorized: false);

  Future<ServerResponse> attemptRegister(
      String username, String password, String email) async =>
      this._sendMessage('register',
          data: {'username': username, 'password': password, 'email': email},
          authorized: false);

  void _processResponse(dynamic stringData) {
    dynamic data;
    try {
      data = jsonDecode(stringData);
    } catch (Exception) {
      this._responder.add(ServerResponse(-1, true, stringData, null));
      return null;
    }

    this._responder.add(ServerResponse(
        data['id'], data['status'] == 'success', data['code'], data['data']));
  }

  Future<bool> tryToAuth({String username, String password}) async {
    if (username == null && password == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      username = prefs.getString('username');
      password = prefs.getString('password');

      if (username == null || password == null) {
        return false;
      }
    }
    return this._tryToEstablishSession(username, password);
  }

  void logOut() {
    if (this._authorizedChannel != null) {
      this._authorizedChannel.sink.close();
      this._authorizedChannel = null;
    }
    this._clearCredentials();
  }

  void _clearCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', null);
    await prefs.setString('password', null);
  }

  Future<ServerResponse> _sendMessage(String action,
      {Map<String, dynamic> data, bool authorized: true}) async {
    int reservedId = this._id++;

    var actionInfo = {'action': action, 'id': reservedId};

    var serverRequest = actionInfo;
    if (data != null) {
      serverRequest.addAll(data);
    }

    if (authorized) {
      try {
        this._authorizedChannel.sink.add(jsonEncode(serverRequest));
      } catch (WebSocketChannelException) {
        try {
          this.tryToAuth().then((bool status) {
            if (status) {
              this._authorizedChannel.sink.add(jsonEncode(serverRequest));
            }
          });
        } catch (WebSocketChannelException) {}
      }
    } else {
      this._guestChannel?.sink?.add(jsonEncode(serverRequest));
    }
    return this._responder.stream.firstWhere((ServerResponse response) {
      return response.id == reservedId;
    });
  }

  Future<bool> _tryToEstablishSession(String username, String password) async {
    if (this._authorizedChannel != null) {
      this._authorizedChannel.sink.close();
    }

    var temporary = IOWebSocketChannel.connect(
        'ws://$WEBSERVER_LOCATION/websocket/$username/$password');

    temporary.stream.listen(this._processResponse);

    return this._responder.stream.firstWhere((ServerResponse response) {
      return ['AUTH_SUCCESSFUL', 'AUTH_FAILED'].contains(response.code);
    }).then((ServerResponse response) {
      switch (response.code) {
        case ('AUTH_SUCCESSFUL'):
          this._authorizedChannel = temporary;
          this
              ._responder
              .stream
              .where((ServerResponse response) => response.id == -1)
              .listen((ServerResponse response) =>
              this.serverBroadcast.add(response));
          this.username = username;
          return true;
        case ('AUTH_FAILED'):
          return false;
      }
    });
  }

  Future<bool> establishGuestSession() async {
    if (this._guestChannel != null) {
      return true;
    }

    this._guestChannel =
        IOWebSocketChannel.connect('ws://$WEBSERVER_LOCATION/websocket');

    this._guestChannel.stream.listen(this._processResponse);

    return this
        ._responder
        .stream
        .firstWhere((ServerResponse response) {
      return response.code == 'GUEST_SESSION';
    })
        .then((ServerResponse response) => true)
        .timeout(Duration(seconds: 2), onTimeout: () => false)
        .then((var result) {
      return result;
    });
  }
}