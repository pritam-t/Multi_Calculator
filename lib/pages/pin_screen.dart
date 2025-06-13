import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/pages/vault_screen.dart';
import '../vault_material/vault_service.dart';

class PinScreen extends StatefulWidget {
  final bool isInitialSetup;
  final bool isUnlockAttempt;

  const PinScreen({
    super.key,
    this.isInitialSetup = false,
    this.isUnlockAttempt = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final VaultService _vaultService = VaultService();
  String _errorMessage = '';
  int _attemptsRemaining = 5;
  bool _isProcessing = false;
  bool _showNewPinField = false;
  final TextEditingController _newPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showNewPinField
              ? 'Set New PIN'
              : widget.isInitialSetup
              ? 'Set Secure PIN'
              : 'Enter Vault PIN'),
          automaticallyImplyLeading: !widget.isUnlockAttempt && !_showNewPinField,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _showNewPinField ? _buildNewPinForm() : _buildPinEntryForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntryForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 50, color: Colors.blue),
        const SizedBox(height: 24),
        TextFormField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '6-digit PIN',
            hintText: 'Enter your PIN',
            errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.pin_outlined),
            counterText: '',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
        if (!widget.isInitialSetup && _attemptsRemaining < 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Attempts remaining: $_attemptsRemaining',
              style: TextStyle(
                color: _attemptsRemaining <= 2 ? Colors.red : Colors.orange,
              ),
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isProcessing
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.lock_open),
            label: Text(
              widget.isInitialSetup ? 'SET SECURE PIN' : 'UNLOCK VAULT',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isProcessing ? null : _onSubmit,
          ),
        ),
        if (!widget.isInitialSetup)
          TextButton(
            child: const Text('Forgot PIN?'),
            onPressed: _isProcessing ? null : _onForgotPin,
          ),
      ],
    );
  }

  Widget _buildNewPinForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_reset, size: 50, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          'Please set a new 6-digit PIN',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'New 6-digit PIN',
            errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.pin_outlined),
            counterText: '',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isProcessing
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.lock),
            label: const Text(
              'SET NEW PIN',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isProcessing ? null : _onSetNewPin,
          ),
        ),
        TextButton(
          onPressed: _isProcessing ? null : () {
            setState(() {
              _showNewPinField = false;
              _errorMessage = '';
            });
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _onForgotPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text('This will clear all vault data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await _vaultService.deleteAllMedia();
        setState(() {
          _showNewPinField = true;
          _newPinController.clear();
          _errorMessage = '';
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to reset vault';
        });
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _onSetNewPin() async {
    final newPin = _newPinController.text.trim();

    if (newPin.length != 6) {
      setState(() => _errorMessage = 'PIN must be 6 digits');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      await _vaultService.setPin(newPin);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VaultScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to set new PIN');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final pin = _pinController.text.trim();

    if (pin.length != 6) {
      setState(() => _errorMessage = 'PIN must be 6 digits');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isProcessing = true;
    });

    try {
      if (widget.isInitialSetup) {
        await _vaultService.setPin(pin);
        _navigateToVault();
      } else {
        final isValid = await _vaultService.validatePin(pin);
        if (isValid) {
          _navigateToVault();
        } else {
          setState(() {
            _attemptsRemaining--;
            _errorMessage = 'Invalid PIN';
            if (_attemptsRemaining <= 0) _lockVault();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _navigateToVault() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VaultScreen()),
    );
  }

  Future<void> _lockVault() async {
    await _vaultService.toggleLock();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}