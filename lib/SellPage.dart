import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:http/http.dart' as http;

class Sellpage extends StatefulWidget {
  final BluetoothDevice server;

  const Sellpage({required this.server});

  @override
  State<Sellpage> createState() => _SellpageState();
}

class _SellpageState extends State<Sellpage> {
  BluetoothConnection? connection;

  String _messageBuffer = '';
  String msg = "";

  String part1 = "";

  Set<String> Tags = {};

  final TextEditingController textEditingController = new TextEditingController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  bool mode = true;

  final invoiceController = TextEditingController();
  final olShopController = TextEditingController();

  String url_single = 'http://192.168.88.54:5000/api/item/item-sold/';
  String url_bulk = 'http://192.168.88.58:5000/api/item/item-sold-bulk';

  @override
  void initState() {
    super.initState();
    // serialNumberController.addListener(controllerToText);
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });

      _sendMessage("R");
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }


  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ' + serverName + '...')
              : isConnected
                  ? Text('Connected with ' + serverName)
                  : Text('Disconnected with ' + serverName))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Received RFID EPC:"),
          Text("$msg\n"),
          
          SizedBox(height: 10),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: invoiceController,
                decoration: InputDecoration(
                    label: Text("Item Invoice"),
                    border: OutlineInputBorder(),
                    hintText: "Enter Invoice",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    )),
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: olShopController,
                decoration: InputDecoration(
                    label: Text("Online Shop"),
                    border: OutlineInputBorder(),
                    hintText: "Enter Shop",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    )),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {

                if (Tags.isEmpty || invoiceController.text.isEmpty || olShopController.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Client Error: All fields must be filled.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          return;
                        }

                try {
                  Map<String, dynamic> data = {
                    "item_tags": Tags.toList(),
                    "invoice": invoiceController.text,
                    "ol_shop": olShopController.text,
                  };
                  sendData(url_bulk, data);
                } catch(error) {
                  Fluttertoast.showToast(
                    msg: "Client Error: Invalid data or data type",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }

                clearController();
                Tags.clear();
              },
              child: Text("Send data")
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  Tags.clear();
                  msg = '';
                });
              },
              child: Text("Clear RFID Data")
            ),
            // const SizedBox(height: 10),
            // ElevatedButton(
            //         onPressed: () {
            //           if (isConnected) {
            //             mode = !mode;
            //             sendMessageCondition(mode);
            //             print(mode);
            //           }
            //         },
            //         child: Text("Change Mode")
            // ),
            // Text(mode ? "RFID Mode" : "QR Mode"),
        ],
      ),
    );
  }

  void clearController() {
    invoiceController.clear();
    olShopController.clear();
  }

  Future<void> sendData(String url, Map<String, dynamic> data) async {
    print("URL: $url");
    print("DATA: $data");
    try {
      // Convert the data map to a JSON string
      String jsonData = jsonEncode(data);
      print(jsonData);
      // Send the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );
      print(response.statusCode);
      print(response);
      // Check the response status code
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        print('Request successful');
        print('Response body: ${response.body}');

        Fluttertoast.showToast(
          msg: "Data sent successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        print('Request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');

        Fluttertoast.showToast(
          msg: "Error ${response.statusCode} : ${response.body}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text)));
        await connection!.output.allSent;

        setState(() {});
      } catch (e) {
        // Ignore error, but notify state
        print("ERROR: $e");
        setState(() {});
      }
    }
  }

  void sendMessageCondition(bool mode) {
    if (mode == true) {
      _sendMessage("R");
    } else {
      _sendMessage("Q");
    }
  }


  void _onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    String dataString = String.fromCharCodes(buffer).trim();

    if (dataString.length < 37) {
      Tags.add(dataString);
    }

    print(dataString);
    print("LIST: $Tags");
    // int index = buffer.indexOf(13);
    if (dataString.isNotEmpty) {
      setState(() {
        msg = Tags.join('\n');
        // msg = backspacesCounter > 0
        //     ? _messageBuffer.substring(
        //         0, _messageBuffer.length - backspacesCounter)
        //     : _messageBuffer + dataString.substring(0, index);
        // _messageBuffer = dataString.substring(index);
        // msg = msg.trim();
        // List<String> parts = msg.split(',');
        // if (parts.length != 2) {
        //   print("Invalid msg format");
        //   return;
        // }

        // part1 = parts[0].trim();
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

}

