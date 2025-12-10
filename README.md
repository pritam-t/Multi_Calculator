# 🔐 Secret Calculator Vault App

A smart calculator app built using **Flutter** that secretly hides photos inside a private vault disguised as a normal calculator. Designed to look and behave like a basic calculator, but can unlock a hidden photo vault using a secret combination.

---

## ✨ Features

- 🎛️ Fully functional calculator UI
- 🔢 Trigger secret vault access with a specific math expression (e.g., `23 + 25 =`)
- 🔐 PIN-protected photo vault
- 📁 Photos are securely moved to private storage and hidden from gallery
- 🌗 Dark and light mode toggle
- 🧠 Persistent storage using Hive DB
- 🧹 Deletes original gallery photo after vaulting
- 🛡️ Optional image encryption (AES-ready)

---

## 📸 Secret Trigger

You can unlock the vault by typing certain combinations in the calculator. For example:
```text
1984 - 1975 =
```

## 🧪 Tech Stack

- **Flutter & Dart 3**
- **Hive** for secure local storage
- **Path Provider** for private directories
- **Encrypt + Crypto** libraries for optional AES encryption
- **Material Design** UI

---

## 🛠️ Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/pritam-t/Multi_Calculator.git
cd secret_calculator_vault
```

### 2. Install dependencies

   flutter pub get

### 3. Run the app

   flutter run

## 🔑 Secret Combinations
You can configure secret expressions in Homepage.dart like:

final List<Map<String, dynamic>> _secretCombinations = [
  {'num1': 23, 'operand': Btn.add, 'num2': 25},
  {'num1': 1984, 'operand': Btn.subtract, 'num2': 1975},
];

## 📂 Vault Directory
Photos are moved to a secure directory:


Android/data/com.yourapp.package/files/private_vault/
A .nomedia file is created to hide these from the gallery.

### 🧯 Known Issues
Dart 3 no longer supports some older media scanner plugins — gallery refresh may not happen instantly.

Image encryption is prepared but not currently active.

## 🚧 Future Enhancements
Enable biometric unlock

Encrypt images before storing

Cloud sync & backup

Secure video support

## 🧑‍💻 Author
Pritam Thopate
LinkedIn | GitHub

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.
