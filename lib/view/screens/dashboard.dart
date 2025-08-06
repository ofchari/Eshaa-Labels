import 'package:eshaa_lab/view/screens/production.dart';
import 'package:eshaa_lab/view/screens/woven_production.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/auth_login.dart';
import '../widgets/subhead.dart';
import '../widgets/text.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.employeeName,
    required this.apiKey,
    required this.process,
    required this.type,
  });
  final String employeeName;
  final String apiKey;
  final String process;
  final String type;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late double height;
  late double width;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Employee Name: ${widget.employeeName}");
    print("API Key: ${widget.apiKey}");
    print("Process: ${widget.process}");
    print("Type: ${widget.type}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Subhead(
          text: "Dashboard",
          color: Colors.white,
          weight: FontWeight.w500,
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () async {
                await AuthService.clearCredentials();
                Get.offAll(
                  () => const Login(),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 500),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.label_outline_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              text: "Welcome back",
                              color: Colors.white.withOpacity(0.9),
                              weight: FontWeight.w500,
                            ),
                            const SizedBox(height: 6),
                            Subhead(
                              text: widget.employeeName,
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // QR Scanner Card
              InkWell(
                onTap: () {
                  if (widget.process == "Woven") {
                    Get.to(
                      () => WovenProduction(
                        employeeName: widget.employeeName,
                        type: widget.type,
                        process: widget.process,
                      ),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 500),
                    );
                  } else {
                    Get.to(
                      Production(
                        employeeName: widget.employeeName,
                        process: widget.process,
                        type: widget.type,
                      ),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 500),
                    );
                    // Handle other processes if needed
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Subhead(
                          text: "QR Scanner",
                          color: Colors.black,
                          weight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        MyText(
                          text: "Scan QR code to start production",
                          color: Colors.grey,
                          weight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
