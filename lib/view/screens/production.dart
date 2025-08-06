import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../universal_api/api&key.dart';
import '../widgets/subhead.dart';
import '../widgets/text.dart';

class Production extends StatefulWidget {
  const Production({
    super.key,
    required this.employeeName,
    required this.process,
    required this.type,
  });
  final String employeeName;
  final String process;
  final String type;

  @override
  State<Production> createState() => _ProductionState();
}

class _ProductionState extends State<Production> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isLoading = false;
  String? scannedJobCard;

  List<dynamic> productionData = [];
  List<TextEditingController> qtyControllers = [];

  @override
  void dispose() {
    cameraController.dispose();
    for (var controller in qtyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && isScanning) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
        });
        _fetchProductionData(code.trim());
      }
    }
  }

  /// Get API for Job card scan //
  Future<void> _fetchProductionData(String jobCard) async {
    setState(() {
      isLoading = true;
      scannedJobCard = jobCard.trim();
    });

    final url = Uri.parse(
      'https://eshaalabels.regenterp.com/api/method/regent.transaction.mobileapp.get_jc_sticker_details?name=$jobCard&process=${Uri.encodeComponent(widget.process.trim())}',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'token $apikey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(response.body);
      print(response.statusCode);
      print(jobCard.trim());
      print(widget.process.trim());
      final items = data['message'] as List;

      setState(() {
        productionData = items;
        qtyControllers = List.generate(
          items.length,
          (_) => TextEditingController(),
        );
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: ${response.statusCode}')),
      );
    }
  }

  /// Post API For Production Data //
  Future<void> postLoginData() async {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "token $apikey",
    };

    final data = {
      "doctype": "Production",
      "job_order_no": scannedJobCard,
      "process_name": widget.process,
      "custom_type": widget.type,
      "customer": productionData[0]['customer'],
      "helper": widget.employeeName,
      "operator": widget.employeeName,
      "total_qty": qtyControllers
          .map((controller) => int.tryParse(controller.text.trim()) ?? 0)
          .reduce((a, b) => a + b),
      "details": qtyControllers
          .asMap()
          .entries
          .where((entry) => entry.value.text.trim().isNotEmpty)
          .map((entry) {
            int index = entry.key;
            TextEditingController controller = entry.value;

            return {
              "product": productionData[index]['product'],
              "product_type": productionData[index]['product_type'],
              "brand": productionData[index]['brand'],
              "style": productionData[index]['style'],
              "colour": productionData[index]['colour'],
              "size": productionData[index]['size'],
              "job_qty": productionData[index]['qty'] ?? 0,
              // int.tryParse(
              //   productionData[index]['job_qty'].toString().trim(),
              // ) ??
              // 0,
              "prod_qty": int.tryParse(controller.text.trim()) ?? 0,
            };
          })
          .toList(),
    };

    print("User Input Data Fields$data");

    final url = "$baseUrl/Production";
    final body = json.encode(data);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      print("This is the status code${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          isScanning = true;
          productionData = [];
          qtyControllers = [];
          scannedJobCard = null;
        });
        print("Data Posted saved successfully");
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        Get.snackbar(
          "Data Scanned",
          "Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );

        print("this is a post Data response : ${response.body}");
      } else {
        if (response.statusCode == 400) {
          Get.snackbar(
            "Error",
            "Invalid Id Or Not Scan correctly",
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
        } else {
          Get.snackbar(
            "Error",
            "Production Qty is greater than Job Qty.",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      throw Exception("Error posting data: $e");
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      productionData = [];
      qtyControllers = [];
      scannedJobCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
        title: Subhead(
          text: "Production",
          color: Colors.white,
          weight: FontWeight.w500,
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (!isScanning)
            IconButton(
              color: Colors.blue,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _resetScanner,
              tooltip: 'Scan Again',
            ),
        ],
      ),
      body: isScanning
          ? MobileScanner(controller: cameraController, onDetect: _onDetect)
          : isLoading
          ? const Center(child: CircularProgressIndicator())
          : productionData.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productionData.length,
              itemBuilder: (context, index) {
                final item = productionData[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.inventory_2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText(
                                      text:
                                          'Product: ${item['product'] ?? '-'}',
                                      color: Colors.black,
                                      weight: FontWeight.w500,
                                    ),
                                    MyText(
                                      text:
                                          'Type: ${item['product_type'] ?? '-'}',
                                      color: Colors.black,
                                      weight: FontWeight.w500,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text: 'Size: ${item['size'] ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text: 'Qty: ${item['qty']?.toString() ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              if (item['brand'] != null)
                                MyText(
                                  text: 'Brand: ${item['brand']}',
                                  color: Colors.black,
                                  weight: FontWeight.w500,
                                ),
                              if (item['style'] != null && item['style'] != '-')
                                MyText(
                                  text: 'Style: ${item['style']}',
                                  color: Colors.black,
                                  weight: FontWeight.w500,
                                ),
                              if (item['colour'] != null)
                                MyText(
                                  text: 'Colour: ${item['colour']}',
                                  color: Colors.black,
                                  weight: FontWeight.w500,
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: qtyControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Enter Product Qty',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No production data found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetScanner,
                    child: const Text('Scan Again'),
                  ),
                ],
              ),
            ),
      floatingActionButton: !isScanning && productionData.isNotEmpty
          ? FloatingActionButton(
              onPressed: postLoginData,
              child: const Icon(Icons.save),
              tooltip: 'Save Production Data',
            )
          : null,
    );
  }
}
