import 'package:flutter/material.dart';
import 'package:simple_calculator/pages/pin_screen.dart';
import '../button_values.dart';
import '../vault_material/vault_service.dart';

class Homepage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const Homepage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String number1 = "";
  String operand = "";
  String number2 = "";
  bool _isSecretMode = false;

  final VaultService _vaultService = VaultService();
  final List<Map<String, dynamic>> _secretCombinations = [
    {'num1': 23, 'operand': Btn.add, 'num2': 25},    // 23+25
    {'num1': 7, 'operand': Btn.multiply, 'num2': 3},  // 7*3
    {'num1': 1984, 'operand': Btn.subtract, 'num2': 1975}, // 1984-1975
  ];

  @override
  void initState() {
    super.initState();
    _vaultService.init();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Theme toggle and secret mode indicator
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.brightness_6),
                        onPressed: widget.onThemeToggle,
                        tooltip: "Toggle Theme",
                      ),
                      Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    ],
                  ),
                  if (_isSecretMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.lock_open,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                ],
              ),
            ),
            // Calculator display
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
            // Calculator buttons
            Wrap(
              children: Btn.buttonValues.map(
                    (value) => SizedBox(
                  width: value == Btn.n0 ? screenSize.width / 2 : screenSize.width / 4,
                  height: screenSize.width / 4,
                  child: buildButton(value),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (number1.isEmpty && operand.isEmpty && number2.isEmpty) return "0";
    return "$number1$operand$number2";
  }

  Widget buildButton(String value) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isDarkMode ? Colors.white24 : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () => onBtnTap(value),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: getTextColor(value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onBtnTap(String value) {
    if (value == Btn.del) {
      delete();
      return;
    }

    if (value == Btn.ac) {
      clearAll();
      return;
    }

    if (value == Btn.per) {
      convertToPercentage();
      return;
    }

    if (value == Btn.calculate) {
      calculate();
      return;
    }

    appendValue(value);
  }

  void calculate() {
    if (number1.isEmpty || operand.isEmpty || number2.isEmpty) return;

    final double num1 = double.parse(number1);
    final double num2 = double.parse(number2);

    // Check for secret combinations first
    for (var combo in _secretCombinations) {
      if (num1 == combo['num1'] &&
          operand == combo['operand'] &&
          num2 == combo['num2']) {
        setState(() => _isSecretMode = true);
        _checkVaultAccess();
        return;
      }
    }

    // Normal calculation
    var result = 0.0;
    switch (operand) {
      case Btn.add:
        result = num1 + num2;
        break;
      case Btn.subtract:
        result = num1 - num2;
        break;
      case Btn.multiply:
        result = num1 * num2;
        break;
      case Btn.divide:
        result = num1 / num2;
        break;
    }

    setState(() {
      number1 = _formatResult(result);
      operand = "";
      number2 = "";
    });
  }

  String _formatResult(double result) {
    if (result % 1 == 0) {
      return result.toInt().toString();
    } else {
      return result.toStringAsFixed(3)
          .replaceAll(RegExp(r"0*$"), "")
          .replaceAll(RegExp(r"\.$"), "");
    }
  }

  void convertToPercentage() {
    if (number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty) {
      calculate();
    }
    if (operand.isNotEmpty) return;

    final number = double.parse(number1);
    setState(() {
      number1 = "${(number / 100)}";
      operand = "";
      number2 = "";
    });
  }

  void clearAll() {
    setState(() {
      number1 = "";
      operand = "";
      number2 = "";
      _isSecretMode = false;
    });
  }

  void delete() {
    setState(() {
      if (number2.isNotEmpty) {
        number2 = number2.substring(0, number2.length - 1);
      } else if (operand.isNotEmpty) {
        operand = "";
      } else if (number1.isNotEmpty) {
        number1 = number1.substring(0, number1.length - 1);
      }
      _isSecretMode = false;
    });
  }

  void appendValue(String value) {
    setState(() {
      if (value != Btn.dot && int.tryParse(value) == null) {
        // Operator pressed
        if (operand.isNotEmpty && number2.isNotEmpty) {
          calculate();
        }
        operand = value;
      } else if (number1.isEmpty || operand.isEmpty) {
        // First number input
        if (value == Btn.dot && number1.contains(Btn.dot)) return;
        if ((value == Btn.dot && number1.isEmpty) || number1 == Btn.n0) {
          value = '0.';
        }
        number1 += value;
      } else if (number2.isEmpty || operand.isNotEmpty) {
        // Second number input
        if (value == Btn.dot && number2.contains(Btn.dot)) return;
        if ((value == Btn.dot && number2.isEmpty) || number2 == Btn.n0) {
          value = '0.';
        }
        number2 += value;
      }
      _isSecretMode = false;
    });
  }

  Future<void> _checkVaultAccess() async {
    final hasPin = await _vaultService.hasPin();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          isInitialSetup: !hasPin,
          isUnlockAttempt: true,
        ),
      ),
    ).then((_) {
      clearAll(); // Reset calculator after returning
    });
  }

  Color getBtnColor(String value) {
    if ([Btn.ac].contains(value)) return Colors.blueGrey;
    if ([Btn.del].contains(value)) return Colors.red;
    if ([Btn.per, Btn.multiply, Btn.add, Btn.subtract, Btn.divide, Btn.calculate]
        .contains(value)) return Colors.orange;
    return widget.isDarkMode ? Colors.black54 : Colors.grey[200]!;
  }

  Color getTextColor(String value) {
    if ([Btn.del, Btn.ac].contains(value)) return Colors.white;
    if ([Btn.per, Btn.multiply, Btn.add, Btn.subtract, Btn.divide, Btn.calculate]
        .contains(value)) return Colors.white;
    return widget.isDarkMode ? Colors.white : Colors.black;
  }
}