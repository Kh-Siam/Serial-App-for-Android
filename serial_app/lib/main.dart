import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Serial App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Serial App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool _flag = false;
  bool _locked = false;
  bool _isPortOpen = false;
  String _received = ' ';
  int _receiveCount = 0;

  ////////////////////////////////////////
  //      Handling Communications       //
  ////////////////////////////////////////

  final int _selectedBaudRate = 115200;
  String _selectedPort = "None";
  String _status = "None";
  late UsbPort _port;
  List<UsbDevice>? _serialList = [];

  @override
  void initState() {
    super.initState();
    _initSerialCommunication();
  }

  void _initSerialCommunication() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    UsbPort? port;

    if (devices.isNotEmpty) {
      port = await devices[0].create();
    }

    setState(() {
      _serialList = devices;
      if (_serialList!.isNotEmpty) {
        _selectedPort = _serialList![0].deviceName;
        _port = port!;
      }
    });
  }

  // ignore: non_constant_identifier_names
  void _UART_receive() async {
    if(_isPortOpen) {
      _port.inputStream!.listen((Uint8List data) {
        setState(() {
          if(_receiveCount == 5) {
            _receiveCount = 0;
            // ignore: prefer_interpolation_to_compose_strings
            _received = String.fromCharCodes(data) + ' ';
            _receiveCount++;
          }
          else {
            // ignore: prefer_interpolation_to_compose_strings
            _received += String.fromCharCodes(data) + ' ';
            _receiveCount++;
          }
        });
      });
    }
  }

  // ignore: non_constant_identifier_names
  void _UART_send(Uint8List data) async {
    await _port.write(data);
  }

  // ignore: non_constant_identifier_names
  void _open_port() async {
    if(!_locked) {
      //open connection
      bool openResult = await _port.open();
      if(!openResult) {
        setState(() {
          _status = "Failed to open";
        });
        return;
      }

      _status = "Open";
      _isPortOpen = true;

      await _port.setDTR(true);
      await _port.setRTS(true);

      _port.setPortParameters(_selectedBaudRate, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      setState(() {
        _locked = true;
      });

      _UART_send(Uint8List.fromList([0x6E, 0x30, 0x30, 0x59, 0x33, 0x46]));
      _UART_receive();
    }
  }

  // ignore: non_constant_identifier_names
  void _close_port() {
    if(_locked) {
      _port.close();
      setState(() {
        _status = "Closed";
        _received = ' ';
        _isPortOpen = false;
        _locked = false;
      });
    }
  }

  ////////////////////////////////////////
  //              Features              //
  ////////////////////////////////////////

  // ignore: non_constant_identifier_names
  void _led_control() {
    if(_isPortOpen) {
      setState(() {
        _flag = !_flag;
      });
      if(_flag) {
        _UART_send(Uint8List.fromList([0x4E, 0x30, 0x30]));
      }
      else {
        _UART_send(Uint8List.fromList([0x6E, 0x30, 0x30]));
      }
    }
  }

  void _test() {
    if(_isPortOpen) {
      _UART_send(Uint8List.fromList(([0x54])));
    }
  }

  // ignore: non_constant_identifier_names
  int _SSDCount = 0;

  // ignore: non_constant_identifier_names
  List<int> map(int value) {
    switch(value) {
      case 0:  return [0x59, 0x33, 0x46];
      case 1:  return [0x59, 0x30, 0x36];
      case 2:  return [0x59, 0x35, 0x42];
      case 3:  return [0x59, 0x34, 0x46];
      case 4:  return [0x59, 0x36, 0x36];
      case 5:  return [0x59, 0x36, 0x44];
      case 6:  return [0x59, 0x37, 0x44];
      case 7:  return [0x59, 0x30, 0x37];
      case 8:  return [0x59, 0x37, 0x46];
      case 9:  return [0x59, 0x36, 0x46];
      default: return [0x59, 0x46, 0x46];
    }
  }

  void _countUp() {
    if(_isPortOpen) {
      if(_SSDCount == 0) {
        _SSDCount = 1;
      }
      else if(_SSDCount == 9) {
        _SSDCount = 0;
      }
      else {
        _SSDCount++;
      }
      _UART_send(Uint8List.fromList(map(_SSDCount)));
    }
  }

  void _countDown() {
    if(_isPortOpen) {
      if(_SSDCount == 0) {
        _SSDCount = 9;
      }
      else if(_SSDCount == 9) {
        _SSDCount = 8;
      }
      else {
        _SSDCount--;
      }
      _UART_send(Uint8List.fromList(map(_SSDCount)));
    }
  }

  ////////////////////////////////////////
  //           User Interface           //
  ////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Settings', style: TextStyle(color: Colors.white ,fontWeight: FontWeight.bold, fontSize: 20.0),),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Port: ', style: TextStyle(color: Colors.white),),
                Text(_selectedPort, style: const TextStyle(color: Colors.red),),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('BaudRate: ', style: TextStyle(color: Colors.white),),
                Text('$_selectedBaudRate', style: const TextStyle(color: Colors.red),),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Port Status: ', style: TextStyle(color: Colors.white),),
                Text(_status, style: const TextStyle(color: Colors.red),),
              ]
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextButton.icon(
                      onPressed: _led_control,
                      icon: const Icon(
                        Icons.lightbulb,
                        color: Colors.red,
                        size: 25,
                      ),
                      label: Text(
                        _flag? 'ON' : 'OFF',
                        style: const TextStyle(
                          fontSize: 20.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextButton.icon(
                      onPressed: _countUp,
                      icon: const Icon(
                        Icons.arrow_upward,
                        color: Colors.red,
                        size: 25,
                      ),
                      label: const Text(
                        'UP',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextButton.icon(
                      onPressed: _countDown,
                      icon: const Icon(
                        Icons.arrow_downward,
                        color: Colors.red,
                        size: 25,
                      ),
                      label: const Text(
                        'DOWN',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                  ),
                ]
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: TextButton(
                          onPressed: _open_port,
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                          child: const Text('Start', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: TextButton(
                        onPressed: _close_port,
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                        child: const Text('Stop', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ]
                ),
                TextButton(
                  onPressed: _test,
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                  child: const Text('Test', style: TextStyle(color: Colors.white),),
                ),
              ]
            ),
            const Text('Data Received:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.0),),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                _received,
                style: const TextStyle(color: Colors.red, fontSize: 20.0),
              ),
            ),
            const Text('developed by', style: TextStyle(color: Colors.white),),
            const Text(
              'K E R N E L',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
