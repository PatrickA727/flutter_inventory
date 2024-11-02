import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_example/SelectBondedDevicePage.dart';

import './MainPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SelectBondedDevicePage());
  }
}
