import 'package:flutter/material.dart';
import 'package:simple_calculator/pin_screen.dart';
import 'package:simple_calculator/vault_screen.dart';
import 'package:simple_calculator/vault_service.dart';

import 'button_values.dart';

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

  String number1  ="";
  String operand = "";
  String number2 = "";
  bool _vaultOpened = false;

  final VaultService _vaultService = VaultService();
  final List<Map<String, dynamic>> _secretCombinations = [
    {'num1': 23, 'operand': Btn.add, 'num2': 25},
    {'num1': 7, 'operand': Btn.multiply, 'num2': 3},
    {'num1': 1984, 'operand': Btn.subtract, 'num2': 1975},
  ];

  @override
  void initState() {
    super.initState();
    _vaultService.init();
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea (
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  IconButton(
                    icon: Icon(Icons.brightness_6),
                    onPressed: widget.onThemeToggle,
                    tooltip: "Toggle Theme",
                  ),
                ],
              ),
            ),
            // output
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    "$number1$operand$number2".isEmpty ? "0" : ("$number1$operand$number2"),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
            //buttons
            Wrap(
              children: Btn.buttonValues.map(
                      (value)=> SizedBox(
                        width: value==Btn.n0?screenSize.width/2:screenSize.width/4,
                          height: screenSize.width/4,
                          child: buildButton(value)
                      ),
              ).toList(),
            )
          ],
        ),
      ),
    );
  }
  Widget buildButton(value){
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Material(
        color:getBtncolor(value),
        clipBehavior: Clip.hardEdge,
        shape: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(100)
        ),
        child: InkWell(
          onTap: ()=> onBtnTap(value),
          child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: [Btn.n0, Btn.n1, Btn.n2, Btn.n3, Btn.n4, Btn.n5, Btn.n6, Btn.n7, Btn.n8, Btn.n9, Btn.dot]
                      .contains(value)
                      ? Colors.white
                      : Colors.black,
                ),
              ),
          ),
        ),
      ),
    );
  }

  void onBtnTap(String value)
  {
    if(value==Btn.del){
      delete();
      return; }

    if(value == Btn.ac){
      clearAll();
      return;
    }

    if(value==Btn.per){
      convertToPercentage();
      return;
    }

    if(value == Btn.calculate){
      calculate();
      return;
    }

    appendValue(value);
  }

  void calculate()
  {
    if(number1.isEmpty) return;
    if(number2.isEmpty) return;
    if(operand.isEmpty) return;

    final double num1 = double.parse(number1);
    final double num2 = double.parse(number2);

    var result= 0.0;
    switch(operand){
      case Btn.add:
       result = num1+num2;
       break;

      case Btn.subtract:
        result = num1-num2;
        break;

      case Btn.multiply:
        result = num1*num2;
        break;

      case Btn.divide:
        result = num1/num2;
        break;

      default:
    }

    // Check for secret combinations
    for (var combo in _secretCombinations) {
      if (num1 == combo['num1'] &&
          operand == combo['operand'] &&
          num2 == combo['num2']) {
          _checkVaultAccess();
        return;
      }
    }

    // Format the result to show maximum 3 decimal digits
    String formattedResult;
    if (result % 1 == 0) {
      // If it's a whole number
      formattedResult = result.toInt().toString();
    } else
    {
      // If it has decimal places
      formattedResult = result.toStringAsFixed(3);
      // Remove trailing zeros after decimal if any
      formattedResult = formattedResult.replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "");
    }
    setState(() {
      number1 = formattedResult;
      if(number1.endsWith(".0"))
        {
          number1 = number1.substring(0,number1.length-2);
        }
      operand="";
      number2="";
    });
  }
  void convertToPercentage()
  {
    if(number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty)
      {
        calculate();
      }
    if(operand.isNotEmpty){
      return;
    }
    final number = double.parse(number1);
    setState(() {
      number1 = "${(number/100)}";
      operand = "";
      number2 = "";
    });
  }
  void clearAll()
  {
    setState(() {
      number1="";
      number2="";
      operand="";
    });
  }
  void delete()
  {
    if(number2.isNotEmpty){
      number2 = number2.substring(0,number2.length-1);
    }
    else if(operand.isNotEmpty)
      {
        operand ="";
      }
    else if(number1.isNotEmpty){
      number1 = number1.substring(0,number1.length-1);
    }

    setState(() {});
  }
  void appendValue(String value)
  {

    if(value!= Btn.dot&&int.tryParse(value)==null)
    {
      if(operand.isNotEmpty&&number2.isNotEmpty)
      {
        calculate();
      }
      operand = value;
    }
    else if(number1.isEmpty || operand.isEmpty)
    {
      if(value==Btn.dot && number1.contains(Btn.dot))return;
      if(value==Btn.dot && number1.isEmpty || number1== Btn.n0)
      {
        value ='0.';
      }
      number1+= value;
    }

    else if(number2.isEmpty || operand.isNotEmpty)
    {
      if(value==Btn.dot && number2.contains(Btn.dot))return;
      if(value==Btn.dot && number2.isEmpty || number2== Btn.n0)
      {
        value ='0.';
      }
      number2+= value;
    }
    setState(() {});
  }
  void _openVault()
  {
    setState(() {
      _vaultOpened = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VaultScreen()),
    ).then((_) {
      setState(() {
        _vaultOpened = false;
      });
    });
    clearAll();
  }
  Future<void> _checkVaultAccess() async
  {
    final hasPin = (await _vaultService.getPhotos()).isNotEmpty;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => hasPin
            ? const PinScreen(isInitialSetup: false)
            : const PinScreen(isInitialSetup: true),
      ),
    ).then((_) {
      clearAll();
    });
  }


  Color getBtncolor(value)
  {
    return
      [Btn.ac].contains(value)? Colors.blueGrey:
      [Btn.per, Btn.multiply, Btn.add, Btn.subtract, Btn.divide, Btn.calculate].contains(value)?Colors.orange:
      [Btn.del].contains(value)?Colors.red:
      Colors.black87;
  }
}
