import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class ResultScreen extends StatelessWidget {
  final Map<String, double> expenses;
  final double predictedMiscellaneous;

  ResultScreen({required this.expenses, required this.predictedMiscellaneous});

  @override
  Widget build(BuildContext context) {
    // Define allowed expense categories (excluding income & financial aid)
    List<String> allowedCategories = [
      "tuition",
      "housing",
      "food",
      "transportation",
      "books_supplies",
      "entertainment",
      "personal_care",
    ];

    // Filter only allowed categories
    Map<String, double> displayedExpenses = {
      for (var entry in expenses.entries)
        if (allowedCategories.contains(entry.key))
          entry.key.replaceAll("_", " ").toTitleCase(): entry.value,
    };

    // Add predicted miscellaneous expense
    displayedExpenses["Savings"] = predictedMiscellaneous;

    // Calculate total expenses for percentage calculation
    double total = displayedExpenses.values.fold(0, (a, b) => a + b);

    // Generate PieChart sections
    List<PieChartSectionData> sections =
        displayedExpenses.entries.map((entry) {
          final percentage = (entry.value / total) * 100;

          return PieChartSectionData(
            title: "${entry.key}\n(${percentage.toStringAsFixed(1)}%)",
            value: entry.value,
            color: _getColorForCategory(entry.key), // Use custom color mapping
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Predicted Savings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "\$${predictedMiscellaneous.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...displayedExpenses.entries.map(
              (entry) => ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  color: _getColorForCategory(
                    entry.key,
                  ), // Get the color for the category
                ),
                title: Text(entry.key),
                trailing: Text("\$${entry.value.toStringAsFixed(2)}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case "tuition":
        return Colors.blue;
      case "housing":
        return Colors.orange;
      case "food":
        return Colors.red;
      case "transportation":
        return Colors.purple;
      case "books supplies":
        return Colors.teal;
      case "entertainment":
        return Colors.amber;
      case "personal care":
        return Colors.indigo;
      case "miscellaneous":
        return Colors.green;
      default:
        return Colors.grey; // Fallback color
    }
  }
}
