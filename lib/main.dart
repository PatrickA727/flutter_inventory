import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_example/SelectBondedDevicePage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './MainPage.dart';

// void main() => runApp(new ExampleApplication());

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(ExampleApplication());
}

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SelectBondedDevicePage());
  }
}
