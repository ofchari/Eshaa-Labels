import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../utils/auth_login.dart';
import '../universal_api/api&key.dart';
import '../widgets/heading.dart';
import '../widgets/subhead.dart';
import '../widgets/text.dart';
import 'dashboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late double height;
  late double width;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  List<String> processList = [];
  List<String> typeList = [];

  String? selectedProcess;
  String? selectedType;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authenticateUser(autoLogin: true);
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final creds = await AuthService.getSavedCredentials();
    if (creds != null) {
      _usernameController.text = creds['username']!;
      _passwordController.text = creds['password']!;
      await _authenticateUser(autoLogin: true);
    }
  }

  Future<void> _authenticateUser({bool autoLogin = false}) async {
    if (!autoLogin && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        '$baseUrl/Employee?fields=["employee_name","api_key","process_name"]&limit_page_length=50000',
      );

      final credentials = base64Encode(utf8.encode(apikey));
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final employees = data['data'] as List;
        print(response.body);
        print(response.statusCode);

        final matchedEmployee = employees.firstWhere(
          (employee) =>
              employee['employee_name'].toString().toLowerCase() ==
                  _usernameController.text.toLowerCase() &&
              employee['api_key'] == _passwordController.text,
          orElse: () => null,
        );

        if (matchedEmployee != null) {
          final employeeName = matchedEmployee['employee_name'];
          final apiKeyValue = matchedEmployee['api_key'];

          // Save credentials
          await AuthService.saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );

          await _fetchEmployeeProcess(employeeName);
          await _fetchEmployeeType(employeeName);

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Subhead(
                text: "Select Process and Type",
                color: Colors.brown,
                weight: FontWeight.w400,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedProcess,
                    hint: Text(
                      'Select Process',
                      style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    items: processList
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: MyText(
                              text: e,
                              color: Colors.blueGrey,
                              weight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedProcess = val),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    hint: Text(
                      'Select Type',
                      style: GoogleFonts.outfit(
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    items: typeList
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: MyText(
                              text: e,
                              color: Colors.blueGrey,
                              weight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (selectedProcess != null && selectedType != null) {
                      Navigator.of(context).pop();
                      Get.off(
                        Dashboard(
                          employeeName: employeeName,
                          apiKey: apiKeyValue,
                          process: selectedProcess!,
                          type: selectedType!,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select both process and type'),
                        ),
                      );
                    }
                  },
                  child: MyText(
                    text: "Continue",
                    color: Colors.grey,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (!autoLogin) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
        }
      }
    } catch (e) {
      print('Error: $e');
      if (!autoLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeeProcess(String name) async {
    final uri = Uri.parse(
      'https://eshaalabels.regenterp.com/api/method/regent.transaction.mobileapp.get_employee_process?name=$name',
    );
    final header = 'token $apikey';

    final response = await http.get(
      uri,
      headers: {'Authorization': header, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print(response.body);
      print(response.statusCode);
      processList = List<String>.from(
        (decoded['message'] as List).map((item) => item['sub_process']),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load process list')));
    }
  }

  Future<void> _fetchEmployeeType(String name) async {
    final uri = Uri.parse(
      'https://eshaalabels.regenterp.com/api/method/regent.transaction.mobileapp.get_employee_type?name=$name',
    );
    final header = 'token $apikey';

    final response = await http.get(
      uri,
      headers: {'Authorization': header, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print(response.body);
      print(response.statusCode);
      typeList = List<String>.from(
        (decoded['message'] as List).map((item) => item['type']),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load type List.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        height = constraints.maxHeight;
        width = constraints.maxWidth;
        if (width <= 600) {
          return _smallBuildLayout();
        } else {
          return Scaffold(
            body: Center(
              child: Text(
                "Please make sure your device is in portrait mode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: height * 0.08),

                // Company Logo/Title
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Image.asset("assets/img.png"),
                      SizedBox(height: 16),
                      HeadingText(
                        text: "Eshaa Labels",
                        color: Colors.blue,
                        weight: FontWeight.w500,
                      ),
                      SizedBox(height: 8),
                      MyText(
                        text: "Professional Label Solutions",
                        color: Colors.grey,
                        weight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.08),

                // Welcome Text
                Center(
                  child: Subhead(
                    text: "Welcome Back",
                    color: Colors.black,
                    weight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 8),

                Center(
                  child: MyText(
                    text: "Please sign in to your account",
                    color: Colors.grey,
                    weight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 40),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Employee Name',
                    hintText: 'Enter your employee name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your employee name';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your API key';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : MyText(
                          text: "Sign In",
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                ),

                SizedBox(height: 30),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Secure Login',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
