import 'package:ccce_application/common/collections/company.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';

class CompanyProvider extends ChangeNotifier {
  List<Company> _allCompanies = [];
  bool _isLoaded = false;

  List<Company> get allCompanies => _allCompanies;
  bool get isLoaded => _isLoaded;

  CompanyProvider() {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(milliseconds: 50));
    fetchAllCompanies();
  }
  Future<void> fetchAllCompanies() async {
    if (_isLoaded) return;

    try {
      bool loadedFromCache = false;
      
      try {
        final cacheSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .get(const GetOptions(source: Source.cache));
        
        if (cacheSnapshot.docs.isNotEmpty) {
          ErrorLogger.logInfo('CompanyProvider', 'Loaded ${cacheSnapshot.docs.length} companies from cache');
          _allCompanies.clear();
          for (final doc in cacheSnapshot.docs) {
            try {
              final company = Company.fromSnapshot(doc);
              _allCompanies.add(company);
            } catch (e) {
              ErrorLogger.logWarning('CompanyProvider', 'Failed to parse cached company');
            }
          }
          _allCompanies.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _isLoaded = true;
          loadedFromCache = true;
          notifyListeners();
        }
      } catch (cacheError) {
        ErrorLogger.logInfo('CompanyProvider', 'Cache miss for companies');
      }
      
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get(const GetOptions(source: Source.server));
      ErrorLogger.logInfo('CompanyProvider', '${loadedFromCache ? 'Refreshed' : 'Fetched'} ${snapshot.docs.length} companies from server');
      _allCompanies.clear();

      for (final doc in snapshot.docs) {
        try {
          final company = Company.fromSnapshot(doc);
          _allCompanies.add(company);
        } catch (e) {
          ErrorLogger.logWarning('CompanyProvider', 'Failed to parse company doc');
        }
      }
      _allCompanies.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      ErrorLogger.logError('CompanyProvider', 'Error fetching companies', error: e);
    }
  }
  
  void sortAlphabetically(){
    _allCompanies = _allCompanies.reversed.toList();
    notifyListeners();
  }
}