import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Map<String, dynamic> TagData = {};

  final TextEditingController textEditingController = new TextEditingController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  bool mode = true;

  final invoiceController = TextEditingController();
  final olShopController = TextEditingController();

  String generateHmac(String secret, String data) {
    final key = utf8.encode(secret);          // Convert secret key to bytes
    final bytes = utf8.encode(data);          // Convert data to bytes
    final hmac = Hmac(sha256, key);           // Create HMAC-SHA256 instance
    return hmac.convert(bytes).toString();    // Generate and return the hash
  }

  final secretKey = dotenv.env["SECRET_KEY"] ?? 'Not Found';

  // String url_single = 'https://2876-118-99-106-112.ngrok-free.app/api/item/item-sold/';
  String url_bulk = 'http://192.168.88.138:5000/api/item/ship-items';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Received RFID EPC:"),
        
              ListView.builder(
                shrinkWrap: true,
                itemCount: Tags.length, // or null for an infinite list
                itemBuilder: (context, index) {
                  return ListTile(
                    minVerticalPadding: 0,
                    minTileHeight: 30,
                    title: Center(
                      child: GestureDetector(
                        onTap: () {
                          // getItemByRFID(Tags.toList()[index]);
                        },
                        child: Text(
                          "${TagData[Tags.toList()[index]]['serial_number']} - ${TagData[Tags.toList()[index]]['type_ref']}",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          Tags.remove(Tags.toList()[index]);
                        });
                      },
                      child: Icon(Icons.delete), // Your trailing icon
                    ),
                  );
                },
              ),
            
            // SizedBox(height: 10),
        
            // Padding(
            //     padding: const EdgeInsets.only(left: 10, right: 10),
            //     child: TextField(
            //       controller: invoiceController,
            //       decoration: InputDecoration(
            //           label: Text("Item Invoice"),
            //           border: OutlineInputBorder(),
            //           hintText: "Enter Invoice",
            //           hintStyle: TextStyle(
            //             color: Colors.grey,
            //           )),
            //     ),
            //   ),
        
              // SizedBox(height: 10),
        
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 10),
              //   child: TextField(
              //     controller: olShopController,
              //     decoration: InputDecoration(
              //         label: Text("Online Shop"),
              //         border: OutlineInputBorder(),
              //         hintText: "Enter Shop",
              //         hintStyle: TextStyle(
              //           color: Colors.grey,
              //         )),
              //   ),
              // ),
        
              SizedBox(height: 10),
        
              ElevatedButton(
                onPressed: () {
        
                  if (Tags.isEmpty) {
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
                    print("Tags: ${Tags}");
                    Map<String, dynamic> data = {
                      "item_tags": Tags.toList(),
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
        
                  setState(() {
                    Tags.clear();
                    msg = '';
                  });
                },
                child: Text("Ship Item's")
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
      ),
    );
  }

  Future<void> getItemByRFID(String rfid_tag) async {
    final String url = 'http://192.168.88.138:5000/api/item/get-sold-by-rfid/${rfid_tag}';
    // print(url);

    try {
      final apiUrl = "/api/item/get-sold-by-rfid/${rfid_tag}";
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final requestSign = timestamp + apiUrl;
      final signature = generateHmac(secretKey, requestSign);

      final response = await http.get(
          Uri.parse(url.trim()),
          headers: {
            'Signature': signature,
            'Timestamp': timestamp,
          }
        );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        var data = jsonDecode(response.body);
        Tags.add(rfid_tag);
        TagData[rfid_tag] = data;
        print("TAG DATA: ${TagData}");
        // return data;
      } else {
        Fluttertoast.showToast(
          msg: "TAG: ${rfid_tag} is not sold",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // return null;
      }

    } catch (e) {
      print("Caught error: ${e}");
      // return null;
    }
  }

  Future<void> sendData(String url, Map<String, dynamic> data) async {
    try {
      final apiUrl = "/api/item/ship-items";
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final requestSign = timestamp + apiUrl;
      final signature = generateHmac(secretKey, requestSign);

      // Convert the data map to a JSON string
      String jsonData = jsonEncode(data);
      print("JSON DATA: ${jsonData}");
      // Send the POST request
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Signature': signature,
          'Timestamp': timestamp,
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


  void _onDataReceived(Uint8List data) async {
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

    if (dataString.length < 37 && !Tags.contains(dataString)) {
      await getItemByRFID(dataString);
      // Tags.add(dataString);
      // TagData[dataString] = TagDataBuffer;
      // print("TAG DATA: ${TagData}");
    }

    // print(dataString);
    // print("LIST: $Tags");
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

