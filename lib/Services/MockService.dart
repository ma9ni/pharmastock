// ────────────────────────────────────────────────────────────────────────────
// MockService — fournit des données factices pour tous les endpoints de l'API.
// Activé via ApiConfig.useMock = true dans api_config.dart
// ────────────────────────────────────────────────────────────────────────────

class MockService {
  // ── Produits ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'materialName': 'Paracetamol 500mg',
      'materialSKU': 'MED-PARA-500',
      'quantity': 420,
      'unit': 'boîtes',
      'logNumber': 'LOT-PARA-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'supplier': 'Sanofi',
      'minStockLevel': 50,
      'isAvailable': true,
      'categoryId': 1,
      'categoryName': 'Analgésiques',
      'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'batches': [
        {
          'id': 101,
          'productId': 1,
          'quantity': 200,
          'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'receivedDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
        {
          'id': 102,
          'productId': 1,
          'quantity': 220,
          'expiryDate': DateTime.now().add(const Duration(days: 300)).toIso8601String(),
          'receivedDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        },
      ],
    },
    {
      'id': '2',
      'materialName': 'Amoxicilline 1g',
      'materialSKU': 'MED-AMOX-1G',
      'quantity': 85,
      'unit': 'boîtes',
      'logNumber': 'LOT-AMOX-2024-B',
      'expiryDate': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
      'supplier': 'GSK',
      'minStockLevel': 100,
      'isAvailable': true,
      'categoryId': 2,
      'categoryName': 'Antibiotiques',
      'createdAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      'batches': [
        {
          'id': 201,
          'productId': 2,
          'quantity': 85,
          'expiryDate': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
          'receivedDate': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        },
      ],
    },
    {
      'id': '3',
      'materialName': 'Ibuprofène 400mg',
      'materialSKU': 'MED-IBU-400',
      'quantity': 310,
      'unit': 'boîtes',
      'logNumber': 'LOT-IBU-2024-C',
      'expiryDate': DateTime.now().add(const Duration(days: 500)).toIso8601String(),
      'supplier': 'Pfizer',
      'minStockLevel': 80,
      'isAvailable': true,
      'categoryId': 1,
      'categoryName': 'Analgésiques',
      'createdAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '4',
      'materialName': 'Doliprane 1000mg',
      'materialSKU': 'MED-DOLI-1000',
      'quantity': 0,
      'unit': 'boîtes',
      'logNumber': 'LOT-DOLI-2023-A',
      'expiryDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'supplier': 'Sanofi',
      'minStockLevel': 50,
      'isAvailable': false,
      'categoryId': 1,
      'categoryName': 'Analgésiques',
      'createdAt': DateTime.now().subtract(const Duration(days: 400)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '5',
      'materialName': 'Oméprazole 20mg',
      'materialSKU': 'MED-OME-20',
      'quantity': 55,
      'unit': 'boîtes',
      'logNumber': 'LOT-OME-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 730)).toIso8601String(),
      'supplier': 'AstraZeneca',
      'minStockLevel': 60,
      'isAvailable': true,
      'categoryId': 3,
      'categoryName': 'Gastro-entérologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 120)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '6',
      'materialName': 'Metformine 500mg',
      'materialSKU': 'MED-MET-500',
      'quantity': 200,
      'unit': 'boîtes',
      'logNumber': 'LOT-MET-2024-B',
      'expiryDate': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      'supplier': 'Merck',
      'minStockLevel': 50,
      'isAvailable': true,
      'categoryId': 4,
      'categoryName': 'Diabétologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 200)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '7',
      'materialName': 'Ventoline 100mcg',
      'materialSKU': 'MED-VENT-100',
      'quantity': 130,
      'unit': 'inhalateurs',
      'logNumber': 'LOT-VENT-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 400)).toIso8601String(),
      'supplier': 'GSK',
      'minStockLevel': 30,
      'isAvailable': true,
      'categoryId': 5,
      'categoryName': 'Pneumologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 50)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '8',
      'materialName': 'Losartan 50mg',
      'materialSKU': 'MED-LOS-50',
      'quantity': 25,
      'unit': 'boîtes',
      'logNumber': 'LOT-LOS-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 600)).toIso8601String(),
      'supplier': 'MSD',
      'minStockLevel': 40,
      'isAvailable': true,
      'categoryId': 6,
      'categoryName': 'Cardiologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '9',
      'materialName': 'Sertraline 50mg',
      'materialSKU': 'MED-SER-50',
      'quantity': 95,
      'unit': 'boîtes',
      'logNumber': 'LOT-SER-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 250)).toIso8601String(),
      'supplier': 'Pfizer',
      'minStockLevel': 30,
      'isAvailable': true,
      'categoryId': 7,
      'categoryName': 'Psychiatrie',
      'createdAt': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '10',
      'materialName': 'Vitamine C 500mg',
      'materialSKU': 'MED-VITC-500',
      'quantity': 500,
      'unit': 'comprimés',
      'logNumber': 'LOT-VITC-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 800)).toIso8601String(),
      'supplier': 'Bayer',
      'minStockLevel': 100,
      'isAvailable': true,
      'categoryId': 8,
      'categoryName': 'Vitamines & Compléments',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '11',
      'materialName': 'Atorvastatine 20mg',
      'materialSKU': 'MED-ATOR-20',
      'quantity': 180,
      'unit': 'boîtes',
      'logNumber': 'LOT-ATOR-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 450)).toIso8601String(),
      'supplier': 'Pfizer',
      'minStockLevel': 50,
      'isAvailable': true,
      'categoryId': 6,
      'categoryName': 'Cardiologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 75)).toIso8601String(),
      'batches': [],
    },
    {
      'id': '12',
      'materialName': 'Cétirizine 10mg',
      'materialSKU': 'MED-CET-10',
      'quantity': 15,
      'unit': 'boîtes',
      'logNumber': 'LOT-CET-2024-A',
      'expiryDate': DateTime.now().add(const Duration(days: 350)).toIso8601String(),
      'supplier': 'UCB Pharma',
      'minStockLevel': 30,
      'isAvailable': true,
      'categoryId': 9,
      'categoryName': 'Allergologie',
      'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      'batches': [],
    },
  ];

  // ── Catégories ────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Analgésiques'},
    {'id': 2, 'name': 'Antibiotiques'},
    {'id': 3, 'name': 'Gastro-entérologie'},
    {'id': 4, 'name': 'Diabétologie'},
    {'id': 5, 'name': 'Pneumologie'},
    {'id': 6, 'name': 'Cardiologie'},
    {'id': 7, 'name': 'Psychiatrie'},
    {'id': 8, 'name': 'Vitamines & Compléments'},
    {'id': 9, 'name': 'Allergologie'},
  ];

  // ── Commandes ─────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-001',
      'productId': '1',
      'productName': 'Paracetamol 500mg',
      'productSku': 'MED-PARA-500',
      'quantity': 100,
      'unit': 'boîtes',
      'logNumber': 'LOG-2024-001',
      'categoryId': 1,
      'type': 'add',
      'status': 'completed',
      'supplier': 'Sanofi',
      'recipient': '',
      'createdBy': 'Demo Manager',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'invoiceNumber': 'INV-2024-0015',
    },
    {
      'id': 'ORD-002',
      'productId': '3',
      'productName': 'Ibuprofène 400mg',
      'productSku': 'MED-IBU-400',
      'quantity': 50,
      'unit': 'boîtes',
      'logNumber': 'LOG-2024-002',
      'categoryId': 1,
      'type': 'export',
      'status': 'completed',
      'supplier': '',
      'recipient': 'Service Urgences',
      'createdBy': 'Demo Manager',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': 'ORD-003',
      'productId': '2',
      'productName': 'Amoxicilline 1g',
      'productSku': 'MED-AMOX-1G',
      'quantity': 200,
      'unit': 'boîtes',
      'logNumber': 'LOG-2024-003',
      'categoryId': 2,
      'type': 'add',
      'status': 'pending',
      'supplier': 'GSK',
      'recipient': '',
      'createdBy': 'Demo Supervisor',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'invoiceNumber': 'INV-2024-0032',
    },
    {
      'id': 'ORD-004',
      'productId': '7',
      'productName': 'Ventoline 100mcg',
      'productSku': 'MED-VENT-100',
      'quantity': 20,
      'unit': 'inhalateurs',
      'logNumber': 'LOG-2024-004',
      'categoryId': 5,
      'type': 'export',
      'status': 'completed',
      'supplier': '',
      'recipient': 'Service Pédiatrie',
      'createdBy': 'Demo Manager',
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': 'ORD-005',
      'productId': '4',
      'productName': 'Doliprane 1000mg',
      'productSku': 'MED-DOLI-1000',
      'quantity': 30,
      'unit': 'boîtes',
      'logNumber': 'LOG-2024-005',
      'categoryId': 1,
      'type': 'disposal',
      'status': 'completed',
      'supplier': '',
      'recipient': '',
      'createdBy': 'Demo Manager',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'notes': 'Produits expirés — mise au rebut réglementaire',
    },
  ];

  // ── Utilisateurs ──────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _users = [
    {
      'id': 'usr-001',
      'email': 'manager@pharma.dz',
      'fullName': 'Ahmed Benali',
      'phoneNumber': '+213 555 001 001',
      'role': 'Admin',
      'isActive': true,
    },
    {
      'id': 'usr-002',
      'email': 'supervisor@pharma.dz',
      'fullName': 'Yasmine Kaci',
      'phoneNumber': '+213 555 002 002',
      'role': 'User',
      'isActive': true,
    },
    {
      'id': 'usr-003',
      'email': 'supervisor2@pharma.dz',
      'fullName': 'Karim Hadj',
      'phoneNumber': '+213 555 003 003',
      'role': 'User',
      'isActive': false,
    },
  ];

  // ── Contacts ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _contacts = [
    {'id': 1, 'name': 'Sanofi Algérie', 'type': 'Supplier', 'phone': '+213 21 00 01 01', 'notes': 'Fournisseur principal'},
    {'id': 2, 'name': 'GSK Maroc', 'type': 'Supplier', 'phone': '+212 522 00 00 02', 'notes': null},
    {'id': 3, 'name': 'Pfizer MENA', 'type': 'Supplier', 'phone': '+971 4 000 0003', 'notes': null},
    {'id': 4, 'name': 'Service Urgences CHU', 'type': 'Recipient', 'phone': '+213 21 10 00 04', 'notes': 'Livraison prioritaire'},
    {'id': 5, 'name': 'Service Pédiatrie', 'type': 'Recipient', 'phone': '+213 21 10 00 05', 'notes': null},
    {'id': 6, 'name': 'Pharmacie Centrale', 'type': 'Recipient', 'phone': '+213 21 10 00 06', 'notes': null},
  ];

  // ── Audit Logs ────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get _auditLogs => [
    {
      'id': 1,
      'action': 'LOGIN',
      'entityType': 'User',
      'entityId': 1,
      'details': 'Connexion réussie depuis 192.168.1.10',
      'userId': 1,
      'userName': 'Ahmed Benali',
      'userRole': 'Admin',
      'ipAddress': '192.168.1.10',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
    },
    {
      'id': 2,
      'action': 'CREATE',
      'entityType': 'Product',
      'entityId': 10,
      'details': 'Ajout de Vitamine C 500mg — Qté: 500 boîtes',
      'userId': 1,
      'userName': 'Ahmed Benali',
      'userRole': 'Admin',
      'ipAddress': '192.168.1.10',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 3,
      'action': 'DISPATCH',
      'entityType': 'Order',
      'entityId': 2,
      'details': 'Sortie de 50 boîtes Ibuprofène 400mg — Destinataire: Service Urgences',
      'userId': 1,
      'userName': 'Ahmed Benali',
      'userRole': 'Admin',
      'ipAddress': '192.168.1.10',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': 4,
      'action': 'UPDATE',
      'entityType': 'Product',
      'entityId': 5,
      'details': 'Mise à jour du seuil minimum de stock: 60 → 80 unités',
      'userId': 2,
      'userName': 'Yasmine Kaci',
      'userRole': 'User',
      'ipAddress': '192.168.1.15',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 5,
      'action': 'DISPOSE',
      'entityType': 'Product',
      'entityId': 4,
      'details': 'Mise au rebut de 30 boîtes Doliprane 1000mg — Lot expiré',
      'userId': 1,
      'userName': 'Ahmed Benali',
      'userRole': 'Admin',
      'ipAddress': '192.168.1.10',
      'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 3)).toIso8601String(),
    },
    {
      'id': 6,
      'action': 'RECEIVE',
      'entityType': 'Order',
      'entityId': 1,
      'details': 'Réception de 100 boîtes Paracetamol 500mg — Fournisseur: Sanofi',
      'userId': 1,
      'userName': 'Ahmed Benali',
      'userRole': 'Admin',
      'ipAddress': '192.168.1.10',
      'timestamp': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
  ];

  // ── Approbations ──────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get _pendingApprovals => [
    {
      'id': 1,
      'batchId': 201,
      'productName': 'Amoxicilline 1g',
      'currentExpiry': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
      'newExpiry': DateTime.now().add(const Duration(days: 50)).toIso8601String(),
      'reason': 'Erreur de saisie lors de la réception',
      'requestedBy': 'Yasmine Kaci',
      'status': 'Pending',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
  ];

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getDashboardActivity({int limit = 10}) {
    return _auditLogs.take(limit).toList();
  }

  static List<Map<String, dynamic>> getStockMovement({int days = 30}) {
    final now = DateTime.now();
    return List.generate(days > 7 ? 7 : days, (i) {
      final date = now.subtract(Duration(days: i));
      return {
        'date': date.toIso8601String(),
        'received': (30 + (i * 7) % 50).toInt(),
        'dispatched': (15 + (i * 5) % 30).toInt(),
      };
    });
  }

  static List<Map<String, dynamic>> getTopConsumed({int? month, int? year}) {
    return [
      {'productName': 'Paracetamol 500mg', 'totalConsumed': 350},
      {'productName': 'Ibuprofène 400mg', 'totalConsumed': 280},
      {'productName': 'Amoxicilline 1g', 'totalConsumed': 210},
      {'productName': 'Ventoline 100mcg', 'totalConsumed': 180},
      {'productName': 'Metformine 500mg', 'totalConsumed': 150},
    ];
  }

  // ── Thresholds ────────────────────────────────────────────────────────────

  static Map<String, dynamic> getThresholds() {
    return {
      'lowStockThreshold': 100,
      'expiringSoonDays': 30,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Méthodes d'accès publiques — retournent des copies pour éviter les
  // modifications accidentelles de l'état interne.
  // ══════════════════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> getProducts() =>
      List<Map<String, dynamic>>.from(_products);

  static List<Map<String, dynamic>> getCategories() =>
      List<Map<String, dynamic>>.from(_categories);

  static List<Map<String, dynamic>> getOrders() =>
      List<Map<String, dynamic>>.from(_orders);

  static List<Map<String, dynamic>> getUsers() =>
      List<Map<String, dynamic>>.from(_users);

  static List<Map<String, dynamic>> getContacts({String? type}) {
    if (type != null && type.isNotEmpty) {
      return _contacts.where((c) => c['type'] == type).toList();
    }
    return List<Map<String, dynamic>>.from(_contacts);
  }

  static List<Map<String, dynamic>> getAuditLogs() =>
      List<Map<String, dynamic>>.from(_auditLogs);

  static List<Map<String, dynamic>> getPendingApprovals() =>
      List<Map<String, dynamic>>.from(_pendingApprovals);

  static List<Map<String, dynamic>> getAllApprovals() =>
      List<Map<String, dynamic>>.from(_pendingApprovals);

  // ── Mutations ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> addProduct(Map<String, dynamic> body) {
    final newId = (_products.length + 1).toString();
    final newProduct = <String, dynamic>{
      'id': newId,
      'materialName': body['name'] ?? body['materialName'] ?? 'Nouveau Produit',
      'materialSKU': body['sku'] ?? body['materialSKU'] ?? 'SKU-$newId',
      'quantity': body['quantity'] ?? 0,
      'unit': body['unit'] ?? 'unités',
      'logNumber': body['lot'] ?? body['logNumber'] ?? '',
      'expiryDate': body['expiryDate'] ?? '',
      'supplier': body['supplier'] ?? '',
      'minStockLevel': body['minStockLevel'] ?? 0,
      'isAvailable': (body['quantity'] ?? 0) > 0,
      'categoryId': body['categoryId'] ?? 0,
      'categoryName': body['categoryName'] ?? body['category'] ?? 'Uncategorized',
      'createdAt': DateTime.now().toIso8601String(),
      'batches': <Map<String, dynamic>>[],
    };
    _products.insert(0, newProduct);
    return newProduct;
  }

  static bool updateProduct(String id, Map<String, dynamic> body) {
    final idx = _products.indexWhere((p) => p['id'] == id);
    if (idx == -1) return false;
    final updated = Map<String, dynamic>.from(_products[idx]);
    body.forEach((key, value) {
      if (value != null) updated[key] = value;
    });
    // Harmonize common field aliases
    if (body.containsKey('name')) updated['materialName'] = body['name'];
    if (body.containsKey('sku')) updated['materialSKU'] = body['sku'];
    _products[idx] = updated;
    return true;
  }

  static bool deleteProduct(String id) {
    final idx = _products.indexWhere((p) => p['id'] == id);
    if (idx == -1) return false;
    _products.removeAt(idx);
    return true;
  }

  static Map<String, dynamic> receiveStock(
      String productId, int quantity, String? expiryDate) {
    final idx = _products.indexWhere((p) => p['id'] == productId);
    if (idx != -1) {
      _products[idx] = Map<String, dynamic>.from(_products[idx])
        ..['quantity'] = (_products[idx]['quantity'] as int) + quantity
        ..['isAvailable'] = true;
      final batches =
          List<Map<String, dynamic>>.from(_products[idx]['batches'] as List);
      batches.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'productId': int.tryParse(productId) ?? 0,
        'quantity': quantity,
        'expiryDate':
            expiryDate ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'receivedDate': DateTime.now().toIso8601String(),
      });
      _products[idx]['batches'] = batches;
    }
    return {'success': true, 'message': 'Stock reçu avec succès'};
  }

  static Map<String, dynamic> getFefoPlan(String productId, int quantity) {
    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => <String, dynamic>{},
    );
    if (product.isEmpty) return {'success': false, 'batches': []};
    final batches = product['batches'] as List;
    return {
      'success': true,
      'batches': batches.map((b) => Map<String, dynamic>.from(b as Map)).toList(),
    };
  }

  static Map<String, dynamic> addCategory(String name) {
    final newId = _categories.length + 1;
    final cat = {'id': newId, 'name': name};
    _categories.add(cat);
    return cat;
  }

  static Map<String, dynamic> updateCategory(int id, String name) {
    final idx = _categories.indexWhere((c) => c['id'] == id);
    if (idx != -1) _categories[idx] = {'id': id, 'name': name};
    return {'id': id, 'name': name};
  }

  static void deleteCategory(int id) {
    _categories.removeWhere((c) => c['id'] == id);
  }

  static Map<String, dynamic> addContact(Map<String, dynamic> body) {
    final newId = _contacts.length + 1;
    final contact = {
      'id': newId,
      'name': body['name'] ?? '',
      'type': body['type'] ?? 'Supplier',
      'phone': body['phone'],
      'notes': body['notes'],
    };
    _contacts.add(contact);
    return contact;
  }

  static Map<String, dynamic> updateContact(int id, Map<String, dynamic> body) {
    final idx = _contacts.indexWhere((c) => c['id'] == id);
    final updated = {
      'id': id,
      'name': body['name'] ?? '',
      'type': body['type'] ?? 'Supplier',
      'phone': body['phone'],
      'notes': body['notes'],
    };
    if (idx != -1) _contacts[idx] = updated;
    return updated;
  }

  static void deleteContact(int id) {
    _contacts.removeWhere((c) => c['id'] == id);
  }

  static Map<String, dynamic> addOrder(Map<String, dynamic> body) {
    final order = Map<String, dynamic>.from(body);
    order['id'] = 'ORD-MOCK-${DateTime.now().millisecondsSinceEpoch}';
    order['createdAt'] = DateTime.now().toIso8601String();
    _orders.insert(0, order);
    return order;
  }

  static bool disposeExpired(String productId) {
    final idx = _products.indexWhere((p) => p['id'] == productId);
    if (idx == -1) return false;
    _products[idx] = Map<String, dynamic>.from(_products[idx])
      ..['quantity'] = 0
      ..['isAvailable'] = false;
    return true;
  }

  static Map<String, dynamic> dispatchFefo(Map<String, dynamic> body) {
    final productId = body['productId']?.toString();
    final qty = body['quantity'] as int? ?? 0;
    if (productId != null) {
      final idx = _products.indexWhere((p) => p['id'] == productId);
      if (idx != -1) {
        final current = _products[idx]['quantity'] as int;
        _products[idx] = Map<String, dynamic>.from(_products[idx])
          ..['quantity'] = (current - qty).clamp(0, current);
      }
    }
    final orderData = {
      'id': 'ORD-FEFO-${DateTime.now().millisecondsSinceEpoch}',
      'productId': productId,
      'productName': body['productName'] ?? '',
      'productSku': body['productSku'] ?? '',
      'quantity': qty,
      'unit': body['unit'] ?? 'unités',
      'logNumber': 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      'categoryId': body['categoryId'] ?? 0,
      'type': 'export',
      'status': 'completed',
      'recipient': body['recipient'] ?? '',
      'supplier': '',
      'createdBy': 'Demo Manager',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _orders.insert(0, orderData);
    return {'success': true, 'order': orderData};
  }

  static void approveRequest(int id) {
    _pendingApprovals.removeWhere((a) => a['id'] == id);
  }

  static void rejectRequest(int id) {
    _pendingApprovals.removeWhere((a) => a['id'] == id);
  }

  static void changeUserRole(String id, String role) {
    final idx = _users.indexWhere((u) => u['id'] == id);
    if (idx != -1) _users[idx]['role'] = role;
  }

  static bool toggleUserStatus(String id) {
    final idx = _users.indexWhere((u) => u['id'] == id);
    if (idx == -1) return false;
    final current = _users[idx]['isActive'] as bool? ?? true;
    _users[idx]['isActive'] = !current;
    return !current;
  }

  static void deleteUser(String id) {
    _users.removeWhere((u) => u['id'] == id);
  }
}
