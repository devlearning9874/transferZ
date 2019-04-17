import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'service_advertising.dart';
import 'service_discovery.dart';

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> implements FoundServiceCallBack {
  MethodChannel _methodChannel;
  String _methodChannelName;
  bool _isPermissionAvailable;
  String _homeDir;
  String _initText;
  List<String> _filesToBeTransferred;

  @override
  void initState() {
    super.initState();
    _filesToBeTransferred = [];
    _methodChannelName = 'io.github.itzmeanjan.transferz';
    _methodChannel = MethodChannel(_methodChannelName);
    _isPermissionAvailable = false;
    _initText = 'Storage Access Permission Required';
    isPermissionAvailable().then((val) {
      if (!val)
        requestPermission().then((res) {
          setState(() {
            _isPermissionAvailable = res;
          });
          if (res)
            getHomeDir().then((value) {
              _homeDir = value;
              createDirectory(_homeDir);
            });
        });
      else {
        setState(() {
          _isPermissionAvailable = true;
        });
        getHomeDir().then((value) {
          _homeDir = value;
          createDirectory(_homeDir);
        });
      }
    });
  }

  Future<bool> isPermissionAvailable() async {
    return await _methodChannel
        .invokeMethod('isPermissionAvailable')
        .then((val) => val);
  }

  Future<bool> requestPermission() async {
    return await _methodChannel
        .invokeMethod('requestPermission')
        .then((val) => val);
  }

  Future<String> getHomeDir() async {
    return await _methodChannel.invokeMethod('getHomeDir',
        <String, String>{'dirName': 'transferZ'}).then((val) => val);
  }

  Future<List<String>> initFileChooser() async {
    return await _methodChannel
        .invokeMethod('initFileChooser')
        .then((val) => List<String>.from(val));
  }

  floatingActionButtonCallBack() {
    requestPermission().then((res) {
      setState(() {
        _isPermissionAvailable = res;
      });
      if (res)
        getHomeDir().then((value) {
          _homeDir = value;
          createDirectory(_homeDir);
        });
    });
  }

  createDirectory(String dirName) {
    Directory directory = Directory(dirName);
    directory.exists().then((val) {
      if (!val) {
        directory.create().then((value) {
          print('directory created -- ${value.path}');
        });
      }
    });
  }

  @override
  foundService(String host, int port) {
    print('[+]Target server $host:$port');
  }

  @override
  Widget build(BuildContext context) {
    return !_isPermissionAvailable
        ? Scaffold(
            appBar: AppBar(
              title: Text('transferZ'),
              backgroundColor: Colors.tealAccent,
              elevation: 16,
            ),
            backgroundColor: Colors.grey,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 100,
                  ),
                  Text(
                    _initText,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: floatingActionButtonCallBack,
              child: Icon(Icons.sd_storage),
              tooltip: 'Grant Storage Access',
              elevation: 16,
              backgroundColor: Colors.teal,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('transferZ'),
              backgroundColor: Colors.tealAccent,
              elevation: 16,
            ),
            body: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [Colors.tealAccent, Colors.cyanAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      iconSize: 60,
                      splashColor: Colors.white,
                      icon: Icon(
                        Icons.file_upload,
                        color: Colors.cyan,
                      ),
                      onPressed: () {
                        var advertiseService = AdvertiseService(8000);
                        advertiseService.advertise();
                        /*initFileChooser().then((filePaths) {
                          filePaths.forEach(
                              (file) => _filesToBeTransferred.add(file));
                        });
                        print(_filesToBeTransferred);*/
                      },
                      tooltip: 'Send File',
                    ),
                    IconButton(
                      splashColor: Colors.white,
                      iconSize: 60,
                      icon: Icon(
                        Icons.file_download,
                        color: Colors.teal,
                      ),
                      onPressed: () {
                        var discoverService = DiscoverService(
                            0,
                            'io.github.itzmeanjan.transferz',
                            '255.255.255.255',
                            8000,
                            this);
                        discoverService.discoverAndReport();
                      },
                      tooltip: 'Receive File',
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}