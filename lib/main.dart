import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  DateTime timeOfIn;
  DateTime timeOfFirstLaunch;
  int maxInactive = 1;
  bool isAppActive = false;
  bool isDemo;
  TextEditingController serialCnt = TextEditingController();
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> checkActivation() async {
    timeOfIn = DateTime.now();
    print('timeOfIn $timeOfIn');

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('serial')) {
      setState(() {
        isAppActive = true;
        print('isAppActive = true');
        isDemo = false;
        print('isDemo = false');
      });
      print('serial founded');
      return;
    }

    if (prefs.containsKey('timeOfFirstLaunch')) {
      timeOfFirstLaunch = DateTime.parse(prefs.getString('timeOfFirstLaunch'));
    } else {
      prefs.setString('timeOfFirstLaunch', timeOfIn.toString());
      timeOfFirstLaunch = timeOfIn;
      setState(() {
        isAppActive = false;
        print('isAppActive false');
      });
    }

    await getIsActive();
  }

  Future<void> getIsActive() async {
    if (timeOfIn.difference(timeOfFirstLaunch) >=
        Duration(minutes: maxInactive)) {
      setState(() {
        isDemo = false;
        print('is demo false');
      });
    } else {
      setState(() {
        isDemo = true;
        isAppActive = false;
        print('is demo true');
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance
        .addObserver(LifecycleEventHandler(resumeCallBack: () async {
      print('resume app');
      await checkActivation();
    }));

    checkActivation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isDemo == null
          ? Center(child: Text('loading...'))
          : Center(
              child: isDemo || isAppActive
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'You have pushed the button this many times:',
                        ),
                        Text(
                          '$_counter',
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        FloatingActionButton(
                          onPressed: _incrementCounter,
                          tooltip: 'Increment',
                          child: Icon(Icons.add),
                        )
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'you should Activate your app!!!',
                          style: TextStyle(color: Colors.red),
                        ),
                        TextField(
                          controller: serialCnt,
                          decoration:
                              InputDecoration(hintText: 'Enter your serial'),
                        ),
                        TextButton(
                            onPressed: () async {
                              if (serialCnt.text == 'serial123') {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();

                                prefs.setString('serial', serialCnt.text);
                                print('activation btn');
                                await checkActivation();
                              }
                            },
                            child: Text('Activate'))
                      ],
                    ),
            ),
    );
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;

  LifecycleEventHandler({
    this.resumeCallBack,
    this.suspendingCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (suspendingCallBack != null) {
          await suspendingCallBack();
        }
        break;
    }
  }
}
