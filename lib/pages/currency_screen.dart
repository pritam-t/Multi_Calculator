import 'package:flutter/material.dart';

class CurrencyScreen extends StatefulWidget
{
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen>
{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Text('Currency Converter'),
            TextField(keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'From',
              border: OutlineInputBorder()
            ),
            ),
            TextField(keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder()
              ),
            ),
          ],
        ),
      ),
    );
  }
}
