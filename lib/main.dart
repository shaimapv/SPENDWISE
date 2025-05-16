import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resultscreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.green),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'SpendWise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginHovered = false;
  bool _isSignUpHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'SpendWise',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Log In Button with Mouse Hover Effect
              MouseRegion(
                onEnter: (_) => setState(() => _isLoginHovered = true),
                onExit: (_) => setState(() => _isLoginHovered = false),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginformScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isLoginHovered ? Colors.green[800] : Colors.green[100],
                    foregroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Log In'),
                ),
              ),

              const SizedBox(height: 10),

              // Sign Up Button with Mouse Hover Effect
              MouseRegion(
                onEnter: (_) => setState(() => _isSignUpHovered = true),
                onExit: (_) => setState(() => _isSignUpHovered = false),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSignUpHovered
                            ? Colors.green[800]
                            : Colors.green[100],
                    foregroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialDataScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const FinancialDataScreen({super.key, this.userData});

  @override
  _FinancialDataScreenState createState() => _FinancialDataScreenState();
}

class _FinancialDataScreenState extends State<FinancialDataScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final List<String> fields = [
      "monthly_income",
      "financial_aid",
      "tuition",
      "housing",
      "food",
      "transportation",
      "book_supply",
      "entertainment",
      "personal_care",
      "miscellaneous",
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController(
        text: widget.userData?[field]?.toString() ?? "",
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in.");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> financialData = {};
    _controllers.forEach((key, controller) {
      financialData[key] = double.tryParse(controller.text) ?? 0;
    });

    try {
      await FirebaseFirestore.instance
          .collection("training_data")
          .doc(user.uid)
          .set(financialData, SetOptions(merge: true));
      print("Data successfully saved!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IncomeSavingsScreen()),
        );
      }
    } catch (e) {
      print("Error saving data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "Enter Your Financial Data",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children:
              _controllers.keys
                  .map((field) => financialField(field, "Enter your $field"))
                  .toList(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.green, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save"),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bar_chart,
                  color: Colors.green,
                  size: 30,
                ),
                onPressed: () {
                  // Navigate to Analytics Screen (if needed)
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget financialField(String label, String hintText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.replaceAll("_", " ").toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _controllers[label],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.green[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IncomeSavingsScreen extends StatefulWidget {
  const IncomeSavingsScreen({super.key});

  @override
  _IncomeSavingsScreenState createState() => _IncomeSavingsScreenState();
}

class _IncomeSavingsScreenState extends State<IncomeSavingsScreen> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _financialAidController = TextEditingController();
  final TextEditingController _tuitionController = TextEditingController();
  final TextEditingController _housingController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _transportationController =
      TextEditingController();
  final TextEditingController _booksSuppliesController =
      TextEditingController();
  final TextEditingController _entertainmentController =
      TextEditingController();
  final TextEditingController _personalCareController = TextEditingController();

  bool _isLoading = false;
  double? predictedMisc;

  Future<void> _predictExpense() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      "http://192.168.102.146:8000/predict",
    ); // Change to your API URL if hosted
    try {
      // Validate all inputs are numbers
      final requestBody = {
        "monthly_income": double.tryParse(_incomeController.text) ?? 0.0,
        "financial_aid": double.tryParse(_financialAidController.text) ?? 0.0,
        "tuition": double.tryParse(_tuitionController.text) ?? 0.0,
        "housing": double.tryParse(_housingController.text) ?? 0.0,
        "food": double.tryParse(_foodController.text) ?? 0.0,
        "transportation":
            double.tryParse(_transportationController.text) ?? 0.0,
        "books_supplies": double.tryParse(_booksSuppliesController.text) ?? 0.0,
        "entertainment": double.tryParse(_entertainmentController.text) ?? 0.0,
        "personal_care": double.tryParse(_personalCareController.text) ?? 0.0,
      };

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          predictedMisc = jsonResponse["predicted_miscellaneous"];
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultScreen(
                  expenses: requestBody.map(
                    (key, value) => MapEntry(key, (value as num).toDouble()),
                  ),
                  predictedMiscellaneous: predictedMisc ?? 0.0,
                ),
          ),
        );
      } else {
        throw Exception("Failed to get prediction: ${response.statusCode}");
      }
    } on SocketException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No internet connection")));
    } on http.ClientException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request timed out")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.green[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Enter Income & Expenses",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Monthly Income", _incomeController),
              _buildTextField("Financial Aid", _financialAidController),
              _buildTextField("Tuition", _tuitionController),
              _buildTextField("Housing", _housingController),
              _buildTextField("Food", _foodController),
              _buildTextField("Transportation", _transportationController),
              _buildTextField("Books & Supplies", _booksSuppliesController),
              _buildTextField("Entertainment", _entertainmentController),
              _buildTextField("Personal Care", _personalCareController),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _predictExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Predict",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

//for predicting other from monthly_income
// class IncomeSavingsScreen extends StatefulWidget {
//   const IncomeSavingsScreen({super.key});

//   @override
//   _IncomeSavingsScreenState createState() => _IncomeSavingsScreenState();
// }

// class _IncomeSavingsScreenState extends State<IncomeSavingsScreen> {
//   final TextEditingController _incomeController = TextEditingController();
//   final TextEditingController _financialAidController = TextEditingController();

//   bool _isLoading = false;
//   Map<String, double>? _predictedExpenses;

//   Future<void> _predictExpenses() async {
//     setState(() {
//       _isLoading = true;
//     });

//     final url = Uri.parse(
//       "http://192.168.1.26:8000/predict",
//     ); // Change to your API URL

//     try {
//       final requestBody = {
//         "monthly_income": double.tryParse(_incomeController.text) ?? 0.0,
//         "financial_aid": double.tryParse(_financialAidController.text) ?? 0.0,
//       };

//       final response = await http
//           .post(
//             url,
//             headers: {"Content-Type": "application/json"},
//             body: jsonEncode(requestBody),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         setState(() {
//           _predictedExpenses = {
//             "tuition": jsonResponse["tuition"].toDouble(),
//             "housing": jsonResponse["housing"].toDouble(),
//             "food": jsonResponse["food"].toDouble(),
//             "transportation": jsonResponse["transportation"].toDouble(),
//             "books_supplies": jsonResponse["books_supplies"].toDouble(),
//             "entertainment": jsonResponse["entertainment"].toDouble(),
//             "personal_care": jsonResponse["personal_care"].toDouble(),
//             "miscellaneous": jsonResponse["miscellaneous"].toDouble(),
//           };
//         });

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (context) => ResultScreen(
//                   income: double.tryParse(_incomeController.text) ?? 0.0,
//                   financialAid:
//                       double.tryParse(_financialAidController.text) ?? 0.0,
//                   predictedExpenses: _predictedExpenses!,
//                 ),
//           ),
//         );
//       } else {
//         throw Exception("Failed to get prediction: ${response.statusCode}");
//       }
//     } on SocketException {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("No internet connection")));
//     } on http.ClientException {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Request timed out")));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: TextField(
//         controller: controller,
//         keyboardType: TextInputType.number,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           filled: true,
//           fillColor: Colors.green[100],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green[50],
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: const Text(
//           "Enter Income Details",
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildTextField("Monthly Income", _incomeController),
//               _buildTextField("Financial Aid", _financialAidController),
//               const SizedBox(height: 30),
//               _isLoading
//                   ? const CircularProgressIndicator()
//                   : ElevatedButton(
//                     onPressed: _predictExpenses,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 50,
//                         vertical: 15,
//                       ),
//                     ),
//                     child: const Text(
//                       "Predict All Expenses",
//                       style: TextStyle(fontSize: 18, color: Colors.white),
//                     ),
//                   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ResultScreen extends StatelessWidget {
//   final double income;
//   final double financialAid;
//   final Map<String, double> predictedExpenses;

//   const ResultScreen({
//     super.key,
//     required this.income,
//     required this.financialAid,
//     required this.predictedExpenses,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final totalExpenses = predictedExpenses.values.fold(
//       0.0,
//       (sum, value) => sum + value,
//     );
//     final remainingBalance = income + financialAid - totalExpenses;

//     return Scaffold(
//       backgroundColor: Colors.green[50],
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: const Text(
//           "Predicted Expenses",
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       "Income Summary",
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         color: Colors.green[800],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     _buildSummaryRow(
//                       "Monthly Income",
//                       "\$${income.toStringAsFixed(2)}",
//                     ),
//                     _buildSummaryRow(
//                       "Financial Aid",
//                       "\$${financialAid.toStringAsFixed(2)}",
//                     ),
//                     const Divider(),
//                     _buildSummaryRow(
//                       "Total Income",
//                       "\$${(income + financialAid).toStringAsFixed(2)}",
//                       isTotal: true,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView(
//                 children: [
//                   Text(
//                     "Predicted Expenses",
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: Colors.green[800],
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   ...predictedExpenses.entries.map(
//                     (entry) => _buildExpenseCard(entry.key, entry.value),
//                   ),
//                   const SizedBox(height: 20),
//                   Card(
//                     color: Colors.green[100],
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           _buildSummaryRow(
//                             "Total Expenses",
//                             "\$${totalExpenses.toStringAsFixed(2)}",
//                             isTotal: true,
//                           ),
//                           const Divider(),
//                           _buildSummaryRow(
//                             "Remaining Balance",
//                             "\$${remainingBalance.toStringAsFixed(2)}",
//                             isTotal: true,
//                             color:
//                                 remainingBalance >= 0
//                                     ? Colors.green
//                                     : Colors.red,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExpenseCard(String category, double amount) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 10),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               _formatCategoryName(category),
//               style: const TextStyle(fontSize: 16),
//             ),
//             Text(
//               "\$${amount.toStringAsFixed(2)}",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(
//     String label,
//     String value, {
//     bool isTotal = false,
//     Color? color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 18 : 16,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: isTotal ? 18 : 16,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatCategoryName(String category) {
//     return category
//         .replaceAll('_', ' ')
//         .split(' ')
//         .map((word) => word[0].toUpperCase() + word.substring(1))
//         .join(' ');
//   }
// }
