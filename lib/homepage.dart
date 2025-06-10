import 'package:flutter/material.dart';

import 'button_values.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  String number1  ="";
  String operand = "";
  String number2 = "";


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea (
        bottom: false,
        child: Column(
          children: [
            //output
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(18.0),
                  child: Text("$number1$operand$number2".isEmpty?"0":("$number1$operand$number2"),
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
              child: Text(value,
                style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24
              ),)
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
  Color getBtncolor(value)
  {
    return
      [Btn.ac].contains(value)? Colors.blueGrey:
      [Btn.per, Btn.multiply, Btn.add, Btn.subtract, Btn.divide, Btn.calculate].contains(value)?Colors.orange:
      [Btn.del].contains(value)?Colors.red:
      Colors.black87;
  }
}
