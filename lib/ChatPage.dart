import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool mode = true;

  String epc_tag = '';
  String qr_code = '';

  bool isDisconnecting = false;
  String msg = ""; // Declare msg as a class-level variable
  final serialNumberController = TextEditingController();
  final itemNameController = TextEditingController();
  // final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final batchController = TextEditingController();

  String? selectedDropdown;

  String url = 'http://192.168.1.20:5000/api/item/register-item';
  String type_url = 'http://192.168.1.20:5000/api/item/get-types';

  Map<String, dynamic> dropdownTypes = {};
  bool isLoading = true;

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
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });

    getItemTypes();
  }

  Future<void> getItemTypes() async {
      try {
        final response = await http.get(Uri.parse(type_url));

        if (response.statusCode >= 200 && response.statusCode <= 299) {
            Map<String, dynamic> data = json.decode(response.body);
            // print("DATA: ${data}");

            setState(() {
              dropdownTypes = data;
              isLoading = false;
            });
            print("TYPES: ${dropdownTypes}");
          } else {
            print('Error: ${response.statusCode}');
            setState(() {
              isLoading = false;
            });
          }
      } catch (e) {
        print('Exception: ${e}');
      }
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

  // void controllerToText(){
  //   final serialNumber=serialNumberController;
  // }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";

    List<Map<String, dynamic>> dropItems = dropdownTypes["types"] != null
    ? List<Map<String, dynamic>>.from(dropdownTypes["types"])
    : [];

    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ' + serverName + '...')
              : isConnected
                  ? Text('Connected with ' + serverName)
                  : Text('Disconnected with ' + serverName))),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("received RFID EPC: $epc_tag")
                ], // Display the msg variabl
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("received SN: $qr_code")
                ], // Display the msg variabl
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Item: ${selectedDropdown ?? 'No item selected'}")
                ], // Display the msg variabl
              ),
        
              SizedBox(
                height: 15.0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: isLoading ? Center(child: CircularProgressIndicator()) : DropdownButton<String>(
                    value: selectedDropdown,
                    hint: Text("Select an Item"),
                    isExpanded: true,
                    items: dropItems.map<DropdownMenuItem<String>>((dropItem) {
                      return DropdownMenuItem<String>(
                        value: dropItem['item_type'], 
                        child: Text(dropItem['item_type']),
                      );
                    }).toList(), 
                    onChanged: (value) {
                      setState(() {
                        selectedDropdown = value;
                      });
                      print("CHOSEN: ${selectedDropdown}");
                    },
                  ),
              ),
        
              // SizedBox(
              //   height: 10.0,
              // ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 10),
              //   child: TextField(
              //     controller: priceController,
              //     decoration: InputDecoration(
              //         label: Text("Price"),
              //         border: OutlineInputBorder(),
              //         hintText: "Input Price",
              //         hintStyle: TextStyle(
              //           color: Colors.grey,
              //         )),
              //   ),
              // ),
        
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                      label: Text("Quantity"),
                      border: OutlineInputBorder(),
                      hintText: "Input Quantity",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      )),
                ),
              ),
        
              SizedBox(
                height: 15.0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: batchController,
                  decoration: InputDecoration(
                      label: Text("Batch"),
                      border: OutlineInputBorder(),
                      hintText: "Input Batch",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      )),
                ),
              ),
        
              SizedBox(
                height: 15.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {

                        if (qr_code.isEmpty || epc_tag.isEmpty || itemNameController.text.isEmpty || quantityController.text.isEmpty || batchController.text.isEmpty) {
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
                            "serial_number": qr_code,
                            "rfid_tag": epc_tag,
                            "item_name": "buffer",
                            "type_ref": selectedDropdown,
                            "quantity": int.parse(quantityController.text),
                            "batch": int.parse(batchController.text)
                          };
                          sendData(url, data);
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
                        setState(() {
                          epc_tag = '';
                          qr_code = '';
                        });

                      },
                      child: Text("Send data")
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                      onPressed: () {
                        if (isConnected) {
                          mode = !mode;
                          sendMessageCondition(mode);
                          print(mode);
                        }
                      },
                      child: Text("Change Mode")
              ),
              Text(mode ? "RFID Mode" : "QR Mode"),
            ],
          ),
        ),
      ),
    );
  }

  String part1 = '';
  String part2 = '';
  void clearController() {
    serialNumberController.clear();
    itemNameController.clear();
    quantityController.clear();
    batchController.clear();
  }

  Future<void> sendData(String url, Map<String, dynamic> data) async {
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

        Fluttertoast.showToast(
          msg: "API Error ${response.statusCode} : ${response.body}",
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

  void sendMessageCondition(bool mode) {
    if (mode == true) {
      _sendMessage("R");
    } else {
      _sendMessage("Q");
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

    String dataString = String.fromCharCodes(buffer);
    print("DATA STRING: $dataString");

    if (mode == true) {
      setState(() {
        epc_tag = dataString.trim();
      });
    } else if (mode == false) {
      setState(() {
        qr_code = dataString.trim();
      });
    }
  }
}

