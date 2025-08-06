import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../universal_api/api&key.dart';
import '../widgets/subhead.dart';
import '../widgets/text.dart';

class WovenProduction extends StatefulWidget {
  const WovenProduction({
    super.key,
    required this.employeeName,
    required this.process,
    required this.type,
  });
  final String employeeName;
  final String process;
  final String type;

  @override
  State<WovenProduction> createState() => _WovenProductionState();
}

class _WovenProductionState extends State<WovenProduction> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isLoading = false;
  String? scannedJobCard;
  String? scannedCustomer;
  String? scannedRefNo;

  List<dynamic> productionData = [];
  List<Map<String, dynamic>> labelDetails = [];
  List<TextEditingController> qtyControllers = [];

  @override
  void dispose() {
    cameraController.dispose();
    for (var controller in qtyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && isScanning) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
        });

        await _fetchWovenProduction(
          code.trim(),
          widget.employeeName.trim(),
          widget.process.trim(),
        );

        // Now scannedJobCard and scannedRefNo are set
        if (scannedJobCard != null && scannedRefNo != null) {
          await fetchLabelDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid Job Card or Reference No')),
          );
        }
      }
    }
  }

  /// Get API for Job card scan //
  Future<void> _fetchWovenProduction(
    String jobCard,
    String customer,
    String ref,
  ) async {
    setState(() {
      isLoading = true;
      scannedJobCard = jobCard.trim();
      scannedCustomer = customer.toString();
      scannedRefNo = ref.toString();
    });

    final url = Uri.parse(
      'https://eshaalabels.regenterp.com/api/method/regent.transaction.mobileapp.get_jc_woven_details?name=$scannedJobCard',
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
      print(customer);
      print(ref);
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

  /// Get API For Referene No //
  Future<void> fetchLabelDetails() async {
    if (scannedJobCard == null || scannedRefNo == null) {
      print(">>> Job card or Ref No is null, skipping API call.");
      return;
    }

    final url = Uri.parse(
      'https://eshaalabels.regenterp.com/api/method/regent.transaction.mobileapp.get_label_details?name=$scannedJobCard&ref_no=$scannedRefNo',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'token $apikey',
        'Content-Type': 'application/json',
      },
    );

    final data = json.decode(response.body);
    print(">>> Label API response: $data");

    if (response.statusCode == 200) {
      print(response.body);
      print(response.statusCode);
      final List<dynamic> items = data['message'];

      labelDetails = items.map<Map<String, dynamic>>((item) {
        return {
          "count": item['count'] ?? '',
          "shade": item['shade'] ?? '',
          "colour": item['colour'] ?? '',
          "req_wt": item['req_wt'] ?? '',
        };
      }).toList();

      print(">>> Parsed Label Details: $labelDetails");
    } else {
      print(">>> Label details fetch failed: ${response.statusCode}");
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
      "custom_type": widget.type,
      "customer": scannedCustomer,
      "ref_no": scannedRefNo,
      "total_qty": qtyControllers
          .where((controller) => controller.text.trim().isNotEmpty)
          .map((controller) => int.tryParse(controller.text.trim()) ?? 0)
          .fold<int>(0, (sum, qty) => sum + qty),
      "custom_details_1": labelDetails
          .where(
            (detail) =>
                detail['count'].toString().trim().isNotEmpty &&
                detail['shade'].toString().trim().isNotEmpty &&
                detail['colour'].toString().trim().isNotEmpty &&
                detail['req_wt'].toString().trim().isNotEmpty,
          )
          .map(
            (detail) => {
              "count": detail['count'],
              "shade": detail['shade'],
              "colour": detail['colour'],
              "req_wt": detail['req_wt'],
            },
          )
          .toList(),
      "custom_production_details": qtyControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((controller) {
            final index = qtyControllers.indexOf(controller);
            final item = productionData[index];

            // Safe conversion for job_qty
            final jobQty = item['qty'];
            int jobQtyInt;
            if (jobQty is int) {
              jobQtyInt = jobQty;
            } else if (jobQty is double) {
              jobQtyInt = jobQty.toInt();
            } else if (jobQty is String) {
              jobQtyInt = int.tryParse(jobQty) ?? 0;
            } else {
              jobQtyInt = 0;
            }

            // Safe conversion for no_of_rpt
            final noOfRpt = item['no_of_rpt'];
            int noOfRptInt;
            if (noOfRpt is int) {
              noOfRptInt = noOfRpt;
            } else if (noOfRpt is double) {
              noOfRptInt = noOfRpt.toInt();
            } else if (noOfRpt is String) {
              noOfRptInt = int.tryParse(noOfRpt) ?? 0;
            } else {
              noOfRptInt = 0;
            }

            return {
              "size": item['size'],
              "no_of_rpt": noOfRptInt,
              "job_qty": jobQtyInt,
              "completed_qty": int.tryParse(controller.text.trim()) ?? 0,
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
            "Failed to scan. Please try again later.",
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
          text: " Woven Production",
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
                                child: MyText(
                                  text: 'Name : ${item['name'] ?? '-'}',
                                  color: Colors.black,
                                  weight: FontWeight.w500,
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
                                text: 'Customer: ${item['customer'] ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text: 'Ref No: ${item['ref_no'] ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text: 'Size: ${item['size'] ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text:
                                    'No of RPT: ${item['no_of_rpt']?.toString() ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              MyText(
                                text: 'Qty: ${item['qty']?.toString() ?? '-'}',
                                color: Colors.black,
                                weight: FontWeight.w500,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: qtyControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Enter completed Qty',
                                  labelStyle: GoogleFonts.dmSans(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
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
              backgroundColor: Colors.blue,
              onPressed: () async {
                await postLoginData();
              },
              child: const Icon(Icons.save),
              tooltip: 'Save Production Data',
            )
          : null,
    );
  }
}
