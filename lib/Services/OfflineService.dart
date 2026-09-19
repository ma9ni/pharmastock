import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static late Box _productsBox;
  static late Box _ordersBox;
  static late Box _pendingBox;
  static bool _initialized = false;
  static const int _webDemoSeedVersion = 2;
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> syncCompletedEvents = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      Hive.init('pharmacy_wms');
    } else {
      final appDocumentDir = await path_provider
          .getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    }
    _productsBox = await Hive.openBox('productsBox');
    _ordersBox = await Hive.openBox('ordersBox');
    _pendingBox = await Hive.openBox('pendingBox');
    if (kIsWeb && _productsBox.get('demoSeedVersion') != _webDemoSeedVersion) {
      await _seedWebDemoData();
    }
    pendingCount.value = _pendingBox.length;
    _initialized = true;
  }

  static Future<void> _seedWebDemoData() async {
    final now = DateTime.now();
    String expiryInDays(int days) =>
        now.add(Duration(days: days)).toIso8601String();

    final products = [
      MaterialModel(
        id: '1',
        name: 'Paracetamol 500mg',
        sku: 'MED-PARA-500',
        quantity: 420,
        unit: 'boxes',
        lot: 'LOT-PARA-2026-A',
        expiryDate: DateTime(
          now.year + 1,
          now.month,
          now.day,
        ).toIso8601String(),
        supplier: 'Atlas Pharma',
        minStockLevel: 80,
        isAvailable: true,
        categoryId: 1,
        category: 'Medication',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      MaterialModel(
        id: '2',
        name: 'Sterile Syringes 5ml',
        sku: 'MED-SYR-005',
        quantity: 95,
        unit: 'packs',
        lot: 'LOT-SYR-2026-B',
        expiryDate: DateTime(
          now.year + 1,
          now.month + 2,
          now.day,
        ).toIso8601String(),
        supplier: 'NeoMedical Supplies',
        minStockLevel: 120,
        isAvailable: true,
        categoryId: 2,
        category: 'Consumables',
        createdAt: now.subtract(const Duration(days: 24)),
      ),
      MaterialModel(
        id: '3',
        name: 'Nitrile Gloves M',
        sku: 'MED-GLV-M',
        quantity: 38,
        unit: 'cartons',
        lot: 'LOT-GLV-2026-C',
        expiryDate: DateTime(
          now.year + 2,
          now.month,
          now.day,
        ).toIso8601String(),
        supplier: 'SafeCare Distribution',
        minStockLevel: 50,
        isAvailable: true,
        categoryId: 2,
        category: 'Consumables',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      MaterialModel(
        id: '4',
        name: 'Insulin Cool Packs',
        sku: 'MED-COOL-INS',
        quantity: 18,
        unit: 'units',
        lot: 'LOT-COOL-2026-D',
        expiryDate: DateTime(
          now.year,
          now.month + 4,
          now.day,
        ).toIso8601String(),
        supplier: 'ColdChain Health',
        minStockLevel: 20,
        isAvailable: true,
        categoryId: 3,
        category: 'Cold Chain',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      MaterialModel(
        id: '5',
        name: 'Amoxicillin 1g',
        sku: 'MED-AMOX-1G',
        quantity: 185,
        unit: 'boxes',
        lot: 'LOT-AMOX-2026-E',
        expiryDate: expiryInDays(240),
        supplier: 'EuroGenerics',
        minStockLevel: 60,
        isAvailable: true,
        categoryId: 4,
        category: 'Antibiotics',
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      MaterialModel(
        id: '6',
        name: 'Azithromycin 500mg',
        sku: 'MED-AZIT-500',
        quantity: 22,
        unit: 'boxes',
        lot: 'LOT-AZIT-2026-F',
        expiryDate: expiryInDays(32),
        supplier: 'EuroGenerics',
        minStockLevel: 40,
        isAvailable: true,
        categoryId: 4,
        category: 'Antibiotics',
        createdAt: now.subtract(const Duration(days: 39)),
      ),
      MaterialModel(
        id: '7',
        name: 'Rapid Glucose Tests',
        sku: 'DIA-GLU-RAPID',
        quantity: 310,
        unit: 'kits',
        lot: 'LOT-GLU-2026-G',
        expiryDate: expiryInDays(420),
        supplier: 'DiagnoCare',
        minStockLevel: 80,
        isAvailable: true,
        categoryId: 5,
        category: 'Diagnostics',
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      MaterialModel(
        id: '8',
        name: 'COVID Antigen Tests',
        sku: 'DIA-COV-AG',
        quantity: 64,
        unit: 'kits',
        lot: 'LOT-COV-2026-H',
        expiryDate: expiryInDays(21),
        supplier: 'DiagnoCare',
        minStockLevel: 50,
        isAvailable: true,
        categoryId: 5,
        category: 'Diagnostics',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      MaterialModel(
        id: '9',
        name: 'Adrenaline 1mg/ml',
        sku: 'EMR-ADREN-1ML',
        quantity: 8,
        unit: 'ampoules',
        lot: 'LOT-ADR-2026-I',
        expiryDate: expiryInDays(65),
        supplier: 'Urgence Pharma',
        minStockLevel: 30,
        isAvailable: true,
        categoryId: 6,
        category: 'Emergency',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      MaterialModel(
        id: '10',
        name: 'Saline Solution 0.9%',
        sku: 'EMR-SAL-500',
        quantity: 144,
        unit: 'bottles',
        lot: 'LOT-SAL-2026-J',
        expiryDate: expiryInDays(510),
        supplier: 'MedFluid',
        minStockLevel: 90,
        isAvailable: true,
        categoryId: 6,
        category: 'Emergency',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      MaterialModel(
        id: '11',
        name: 'FFP2 Masks',
        sku: 'PPE-MASK-FFP2',
        quantity: 520,
        unit: 'boxes',
        lot: 'LOT-MASK-2026-K',
        expiryDate: expiryInDays(900),
        supplier: 'SafeCare Distribution',
        minStockLevel: 150,
        isAvailable: true,
        categoryId: 7,
        category: 'PPE',
        createdAt: now.subtract(const Duration(days: 44)),
      ),
      MaterialModel(
        id: '12',
        name: 'Surgical Gowns L',
        sku: 'PPE-GOWN-L',
        quantity: 46,
        unit: 'cartons',
        lot: 'LOT-GOWN-2026-L',
        expiryDate: expiryInDays(720),
        supplier: 'SafeCare Distribution',
        minStockLevel: 45,
        isAvailable: true,
        categoryId: 7,
        category: 'PPE',
        createdAt: now.subtract(const Duration(days: 34)),
      ),
      MaterialModel(
        id: '13',
        name: 'Insulin Glargine Pens',
        sku: 'COLD-INS-GLAR',
        quantity: 26,
        unit: 'pens',
        lot: 'LOT-GLAR-2026-M',
        expiryDate: expiryInDays(18),
        supplier: 'ColdChain Health',
        minStockLevel: 35,
        isAvailable: true,
        categoryId: 3,
        category: 'Cold Chain',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      MaterialModel(
        id: '14',
        name: 'Vaccine Carrier 5L',
        sku: 'COLD-CARR-5L',
        quantity: 11,
        unit: 'units',
        lot: 'LOT-CARR-2026-N',
        expiryDate: expiryInDays(1100),
        supplier: 'ColdChain Health',
        minStockLevel: 10,
        isAvailable: true,
        categoryId: 3,
        category: 'Cold Chain',
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      MaterialModel(
        id: '15',
        name: 'Blood Pressure Monitors',
        sku: 'DIA-BP-MON',
        quantity: 17,
        unit: 'units',
        lot: 'LOT-BPM-2026-O',
        expiryDate: expiryInDays(1400),
        supplier: 'MedTech Pro',
        minStockLevel: 12,
        isAvailable: true,
        categoryId: 5,
        category: 'Diagnostics',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      MaterialModel(
        id: '16',
        name: 'Ibuprofen 400mg',
        sku: 'MED-IBU-400',
        quantity: 210,
        unit: 'boxes',
        lot: 'LOT-IBU-2026-P',
        expiryDate: expiryInDays(390),
        supplier: 'Atlas Pharma',
        minStockLevel: 70,
        isAvailable: true,
        categoryId: 1,
        category: 'Medication',
        createdAt: now.subtract(const Duration(days: 31)),
      ),
      MaterialModel(
        id: '17',
        name: 'Alcohol Swabs',
        sku: 'CON-SWAB-ALC',
        quantity: 72,
        unit: 'packs',
        lot: 'LOT-SWAB-2026-Q',
        expiryDate: expiryInDays(27),
        supplier: 'NeoMedical Supplies',
        minStockLevel: 100,
        isAvailable: true,
        categoryId: 2,
        category: 'Consumables',
        createdAt: now.subtract(const Duration(days: 58)),
      ),
      MaterialModel(
        id: '18',
        name: 'Morphine 10mg/ml',
        sku: 'EMR-MORPH-10',
        quantity: 0,
        unit: 'ampoules',
        lot: 'LOT-MOR-2026-R',
        expiryDate: expiryInDays(75),
        supplier: 'Urgence Pharma',
        minStockLevel: 15,
        isAvailable: false,
        categoryId: 6,
        category: 'Emergency',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    final orders = [
      OrderModel(
        id: 'PH-PO-2026-001',
        productId: '1',
        productName: 'Paracetamol 500mg',
        productSku: 'MED-PARA-500',
        quantity: 120,
        unit: 'boxes',
        logNumber: 'LOT-PARA-2026-A',
        categoryId: 1,
        type: OrderType.add,
        status: OrderStatus.completed,
        supplier: 'Atlas Pharma',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 7)),
        invoiceNumber: 'PH-PO-2026-001',
        notes: 'Initial replenishment after monthly inventory count.',
      ),
      OrderModel(
        id: 'PH-DSP-2026-014',
        productId: '2',
        productName: 'Sterile Syringes 5ml',
        productSku: 'MED-SYR-005',
        quantity: 35,
        unit: 'packs',
        logNumber: 'LOT-SYR-2026-B',
        categoryId: 2,
        type: OrderType.export,
        status: OrderStatus.completed,
        recipient: 'Central Clinic',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 2)),
        invoiceNumber: 'PH-DSP-2026-014',
        notes: 'Routine dispatch for outpatient care unit.',
      ),
      OrderModel(
        id: 'PH-PO-2026-002',
        productId: '5',
        productName: 'Amoxicillin 1g',
        productSku: 'MED-AMOX-1G',
        quantity: 90,
        unit: 'boxes',
        logNumber: 'LOT-AMOX-2026-E',
        categoryId: 4,
        type: OrderType.add,
        status: OrderStatus.completed,
        supplier: 'EuroGenerics',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 12)),
        invoiceNumber: 'PH-PO-2026-002',
        notes: 'Supplier delivery received and checked.',
      ),
      OrderModel(
        id: 'PH-REQ-2026-021',
        productId: '13',
        productName: 'Insulin Glargine Pens',
        productSku: 'COLD-INS-GLAR',
        quantity: 18,
        unit: 'pens',
        logNumber: 'LOT-GLAR-2026-M',
        categoryId: 3,
        type: OrderType.export,
        status: OrderStatus.completed,
        recipient: 'Endocrinology Ward',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 1)),
        invoiceNumber: 'PH-REQ-2026-021',
        expiryDate: expiryInDays(18),
        notes: 'Cold-chain dispatch with expiry control.',
      ),
      OrderModel(
        id: 'PH-REQ-2026-022',
        productId: '9',
        productName: 'Adrenaline 1mg/ml',
        productSku: 'EMR-ADREN-1ML',
        quantity: 10,
        unit: 'ampoules',
        logNumber: 'LOT-ADR-2026-I',
        categoryId: 6,
        type: OrderType.export,
        status: OrderStatus.pending,
        recipient: 'Emergency Department',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(hours: 6)),
        invoiceNumber: 'PH-REQ-2026-022',
        notes: 'Pending approval because current stock is below threshold.',
      ),
      OrderModel(
        id: 'PH-PO-2026-003',
        productId: '18',
        productName: 'Morphine 10mg/ml',
        productSku: 'EMR-MORPH-10',
        quantity: 40,
        unit: 'ampoules',
        logNumber: 'LOT-MOR-2026-S',
        categoryId: 6,
        type: OrderType.add,
        status: OrderStatus.pending,
        supplier: 'Urgence Pharma',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(hours: 3)),
        invoiceNumber: 'PH-PO-2026-003',
        notes:
            'Controlled product replenishment awaiting pharmacist validation.',
      ),
      OrderModel(
        id: 'PH-DISP-2026-004',
        productId: '8',
        productName: 'COVID Antigen Tests',
        productSku: 'DIA-COV-AG',
        quantity: 12,
        unit: 'kits',
        logNumber: 'LOT-COV-2026-H',
        categoryId: 5,
        type: OrderType.disposal,
        status: OrderStatus.completed,
        recipient: 'Quality Control',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 4)),
        invoiceNumber: 'PH-DISP-2026-004',
        expiryDate: expiryInDays(21),
        notes: 'Damaged packaging removed from available stock.',
      ),
      OrderModel(
        id: 'PH-ADJ-2026-005',
        productId: '17',
        productName: 'Alcohol Swabs',
        productSku: 'CON-SWAB-ALC',
        quantity: 20,
        unit: 'packs',
        logNumber: 'LOT-SWAB-2026-Q',
        categoryId: 2,
        type: OrderType.edit,
        status: OrderStatus.completed,
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 3)),
        invoiceNumber: 'PH-ADJ-2026-005',
        expiryDate: expiryInDays(27),
        notes: 'Stock correction after cycle count.',
      ),
      OrderModel(
        id: 'PH-REQ-2026-023',
        productId: '11',
        productName: 'FFP2 Masks',
        productSku: 'PPE-MASK-FFP2',
        quantity: 75,
        unit: 'boxes',
        logNumber: 'LOT-MASK-2026-K',
        categoryId: 7,
        type: OrderType.export,
        status: OrderStatus.completed,
        recipient: 'Surgery Department',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 5)),
        invoiceNumber: 'PH-REQ-2026-023',
        notes: 'Weekly PPE allocation.',
      ),
      OrderModel(
        id: 'PH-PO-2026-004',
        productId: '7',
        productName: 'Rapid Glucose Tests',
        productSku: 'DIA-GLU-RAPID',
        quantity: 160,
        unit: 'kits',
        logNumber: 'LOT-GLU-2026-G',
        categoryId: 5,
        type: OrderType.add,
        status: OrderStatus.completed,
        supplier: 'DiagnoCare',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 15)),
        invoiceNumber: 'PH-PO-2026-004',
        notes: 'Bulk purchase for diabetes screening campaign.',
      ),
      OrderModel(
        id: 'PH-REQ-2026-024',
        productId: '6',
        productName: 'Azithromycin 500mg',
        productSku: 'MED-AZIT-500',
        quantity: 16,
        unit: 'boxes',
        logNumber: 'LOT-AZIT-2026-F',
        categoryId: 4,
        type: OrderType.export,
        status: OrderStatus.canceled,
        recipient: 'Pediatrics Ward',
        createdBy: 'Demo Manager',
        createdAt: now.subtract(const Duration(days: 9)),
        invoiceNumber: 'PH-REQ-2026-024',
        expiryDate: expiryInDays(32),
        notes: 'Canceled after therapeutic substitution.',
      ),
    ];

    await _productsBox.put('list', products.map((p) => p.toJson()).toList());
    await _ordersBox.put('list', orders.map((o) => o.toJson()).toList());
    await _productsBox.put('demoSeedVersion', _webDemoSeedVersion);
  }

  static Future<void> cacheProducts(List<MaterialModel> products) async {
    await init();
    final list = products.map((p) => p.toJson()).toList();
    await _productsBox.put('list', list);
  }

  static Future<List<MaterialModel>> getCachedProducts() async {
    await init();
    final raw = _productsBox.get('list');
    if (raw is List) {
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MaterialModel.fromJson(map);
      }).toList();
    }
    return [];
  }

  static Future<void> cacheOrders(List<OrderModel> orders) async {
    await init();
    final list = orders.map((o) => o.toJson()).toList();
    await _ordersBox.put('list', list);
  }

  static Future<List<OrderModel>> getCachedOrders() async {
    await init();
    final raw = _ordersBox.get('list');
    if (raw is List) {
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return OrderModel.fromJson(map);
      }).toList();
    }
    return [];
  }

  static Future<void> queueOperation({
    required String method,
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    await init();
    final opId = 'OP-${DateTime.now().millisecondsSinceEpoch}';
    final opData = {
      'id': opId,
      'method': method,
      'endpoint': endpoint,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _pendingBox.put(opId, opData);
    pendingCount.value = _pendingBox.length;
  }

  static Future<void> syncPendingOperations() async {
    await init();
    if (_pendingBox.isEmpty) return;

    final keys = List.from(_pendingBox.keys);
    keys.sort((a, b) {
      final aMap = _pendingBox.get(a) as Map;
      final bMap = _pendingBox.get(b) as Map;
      return (aMap['timestamp'] as String).compareTo(
        bMap['timestamp'] as String,
      );
    });

    bool syncedAny = false;
    for (final key in keys) {
      final op = Map<String, dynamic>.from(_pendingBox.get(key) as Map);
      final success = await _replayOperation(op);
      if (success) {
        await _pendingBox.delete(key);
        syncedAny = true;
      }
    }
    pendingCount.value = _pendingBox.length;

    if (syncedAny) {
      syncCompletedEvents.value++;
    }
  }

  static Future<bool> _replayOperation(Map<String, dynamic> op) async {
    final method = op['method'] as String;
    final endpoint = op['endpoint'] as String;
    final body = op['body'] as Map<String, dynamic>;
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      http.Response response;
      final headers = AuthService.authHeaders;

      if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == 'PATCH') {
        response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        return false;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint(
        '[OfflineService] Replay failed with status: ${response.statusCode}',
      );
      if (response.statusCode >= 400 && response.statusCode < 500) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[OfflineService] Replay error: $e');
      return false;
    }
  }
}
