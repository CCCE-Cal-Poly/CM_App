import 'package:ccce_application/common/collections/company.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyProvider extends ChangeNotifier {
  List<Company> _allCompanies = [];
  bool _isLoaded = false;

  List<Company> get allCompanies => _allCompanies;
  bool get isLoaded => _isLoaded;

  CompanyProvider() {
    fetchAllCompanies();
  }
  Future<void> fetchAllCompanies() async {
    if (_isLoaded) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('companies').get();
      print("Fetched");
      _allCompanies.clear();

      for (final doc in snapshot.docs) {
        try {
          final company = Company.fromSnapshot(doc);
          print("✅ Loaded company");
          _allCompanies.add(company);
        } catch (e) {
          print("⚠️ Failed to parse company doc");
        }
      }
      _allCompanies.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error fetching companies: $e');
    }
  }
  
  void sortAlphabetically(){
    _allCompanies = _allCompanies.reversed.toList();
    notifyListeners();
  }
}