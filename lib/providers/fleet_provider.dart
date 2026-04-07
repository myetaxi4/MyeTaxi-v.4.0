import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/trip.dart';
import '../models/alert.dart';
import '../data/dummy_data.dart';

// ─── DEMO MODE TOGGLE ────────────────────────────────────────────────────────
// Set to true for offline testing with dummy data, false for live Firestore
const bool kDemoMode = true;

final authProvider = StreamProvider<User?>((ref) {
  if (kDemoMode) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  if (kDemoMode) return 'demo-owner-001';
  return ref.watch(authProvider).value?.uid;
});

// ─── VEHICLES ────────────────────────────────────────────────────────────────

final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  if (kDemoMode) return Stream.value(DummyData.vehicles);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('vehicles')
      .where('ownerId', isEqualTo: uid)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Vehicle.fromFirestore).toList());
});

final vehicleProvider = StreamProvider.family<Vehicle?, String>((ref, id) {
  if (kDemoMode) {
    final match = DummyData.vehicles.where((v) => v.id == id);
    return Stream.value(match.isNotEmpty ? match.first : null);
  }
  return FirebaseFirestore.instance
      .collection('vehicles')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Vehicle.fromFirestore(s) : null);
});

// ─── DRIVERS ─────────────────────────────────────────────────────────────────

final driversProvider = StreamProvider<List<Driver>>((ref) {
  if (kDemoMode) return Stream.value(DummyData.drivers);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('drivers')
      .where('ownerId', isEqualTo: uid)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Driver.fromFirestore).toList());
});

// ─── TRIPS ───────────────────────────────────────────────────────────────────

final todayTripsProvider = StreamProvider<List<Trip>>((ref) {
  if (kDemoMode) return Stream.value(DummyData.trips);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  return FirebaseFirestore.instance
      .collection('trips')
      .where('ownerId', isEqualTo: uid)
      .where('startTime', isGreaterThan: Timestamp.fromDate(startOfDay))
      .orderBy('startTime', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Trip.fromFirestore).toList());
});

final vehicleTripsProvider = StreamProvider.family<List<Trip>, String>((ref, vehicleId) {
  if (kDemoMode) {
    return Stream.value(
      DummyData.trips.where((t) => t.vehicleId == vehicleId).toList(),
    );
  }
  return FirebaseFirestore.instance
      .collection('trips')
      .where('vehicleId', isEqualTo: vehicleId)
      .orderBy('startTime', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Trip.fromFirestore).toList());
});

// ─── ALERTS ──────────────────────────────────────────────────────────────────

final alertsProvider = StreamProvider<List<AppAlert>>((ref) {
  if (kDemoMode) return Stream.value(DummyData.alerts);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('alerts')
      .where('ownerId', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(AppAlert.fromFirestore).toList());
});

final unreadAlertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider).value ?? [];
  return alerts.where((a) => !a.isRead).length;
});

// ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

class DashboardStats {
  final int totalVehicles;
  final int movingVehicles;
  final int idleVehicles;
  final double todayRevenue;
  final double todayDistance;
  final int todayTrips;
  final int urgentAlerts;

  DashboardStats({
    required this.totalVehicles,
    required this.movingVehicles,
    required this.idleVehicles,
    required this.todayRevenue,
    required this.todayDistance,
    required this.todayTrips,
    required this.urgentAlerts,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final vehicles = ref.watch(vehiclesProvider).value ?? [];
  final trips = ref.watch(todayTripsProvider).value ?? [];
  final alerts = ref.watch(alertsProvider).value ?? [];

  return DashboardStats(
    totalVehicles: vehicles.length,
    movingVehicles: vehicles.where((v) => v.status == VehicleStatus.moving).length,
    idleVehicles: vehicles.where((v) => v.status == VehicleStatus.idle).length,
    todayRevenue: trips.fold(0, (sum, t) => sum + t.estimatedRevenue),
    todayDistance: trips.fold(0, (sum, t) => sum + t.distanceKm),
    todayTrips: trips.length,
    urgentAlerts: alerts.where((a) =>
      !a.isRead && a.severity == AlertSeverity.critical).length,
  );
});

// ─── FIRESTORE OPERATIONS ────────────────────────────────────────────────────

class FleetRepository {
  static final _db = FirebaseFirestore.instance;

  static Future<void> addVehicle(Vehicle v) async {
    if (kDemoMode) return;
    await _db.collection('vehicles').add(v.toFirestore());
  }

  static Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    if (kDemoMode) return;
    await _db.collection('vehicles').doc(id).update(data);
  }

  static Future<void> deleteVehicle(String id) async {
    if (kDemoMode) return;
    await _db.collection('vehicles').doc(id).delete();
  }

  static Future<void> addDriver(Driver d) async {
    if (kDemoMode) return;
    await _db.collection('drivers').add(d.toFirestore());
  }

  static Future<void> updateDriver(String id, Map<String, dynamic> data) async {
    if (kDemoMode) return;
    await _db.collection('drivers').doc(id).update(data);
  }

  static Future<void> deleteDriver(String id) async {
    if (kDemoMode) return;
    await _db.collection('drivers').doc(id).delete();
  }

  static Future<void> markAlertRead(String id) async {
    if (kDemoMode) return;
    await _db.collection('alerts').doc(id).update({'isRead': true});
  }

  static Future<void> markAllAlertsRead(String ownerId) async {
    if (kDemoMode) return;
    final batch = _db.batch();
    final snap = await _db
        .collection('alerts')
        .where('ownerId', isEqualTo: ownerId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> deleteAlert(String id) async {
    if (kDemoMode) return;
    await _db.collection('alerts').doc(id).delete();
  }
}
