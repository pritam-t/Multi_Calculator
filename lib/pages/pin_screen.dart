import 'package:flutter/material.dart';
import 'package:simple_calculator/pages/vault_screen.dart';
import '../vault_service.dart';

class PinScreen extends StatefulWidget {
  final bool isInitialSetup;

  const PinScreen({super.key, this.isInitialSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final VaultService _vaultService = VaultService();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Set PIN' : 'Enter PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit PIN',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onSubmit,
              child: Text(widget.isInitialSetup ? 'Set PIN' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    final pin = _pinController.text.trim();

    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be exactly 6 digits';
      });
      return;
    }

    setState(() => _errorMessage = '');

    if (widget.isInitialSetup) {
      await _vaultService.setPin(pin);
      _navigateToVault();
    } else {
      final isValid = await _vaultService.validatePin(pin);
      if (isValid) {
        _navigateToVault();
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
        });
      }
    }
  }

  void _navigateToVault() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VaultScreen()),
    );
  }
}
