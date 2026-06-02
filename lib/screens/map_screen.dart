// lib/screens/map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../models/route_feedback_prediction_models.dart';
import '../services/app_settings_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/locale_helper.dart';

const String _flaskBaseUrl = AppConfig.apiBaseUrl;
const LatLng _istanbulCenter = LatLng(41.0082, 28.9784);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final _fs = FirestoreService();
  final _settings = AppSettingsService();
  final _notifier = NotificationService();

  bool _isLoading = false;
  bool _showBottomSheet = false;
  String _selectedRouteId = '';
  PredictionModel? _selectedPrediction;
  List<Map<String, dynamic>> _forecastPoints = [];
  List<Map<String, dynamic>> _activeIncidents = [];
  List<Map<String, dynamic>> _alternativeRoutes = [];
  bool _isLoadingAlternatives = false;

  List<RouteModel> _searchResults = []; 
  bool _showSearchResults = false;
  AppLanguage _language = AppLanguage.tr;
  final Map<String, DateTime> _lastDensityAlertAt = {};
  final Map<String, DateTime> _lastIncidentAlertAt = {};
  bool get _isEn => _language == AppLanguage.en;
  String _t(String tr, String en) => _isEn ? en : tr;

final List<RouteModel> _allRoutes = [
    // Metro
    RouteModel(routeId: 'M1A',  lineName: 'M1A Yenikapı–Atatürk Hava Limanı', type: TransportType.metro),
    RouteModel(routeId: 'M2',   lineName: 'M2 Yenikapı–Hacıosman',             type: TransportType.metro),
    RouteModel(routeId: 'M3',   lineName: 'M3 Kirazlı–Olimpiyat',              type: TransportType.metro),
    RouteModel(routeId: 'M4',   lineName: 'M4 Kadıköy–Sabiha Gökçen',          type: TransportType.metro),
    RouteModel(routeId: 'M5',   lineName: 'M5 Üsküdar–Çekmeköy',              type: TransportType.metro),
    RouteModel(routeId: 'M6',   lineName: 'M6 Levent–Boğaziçi Üniversitesi',  type: TransportType.metro),
    RouteModel(routeId: 'M7',   lineName: 'M7 Mahmutbey–Mecidiyeköy',         type: TransportType.metro),
    RouteModel(routeId: 'M9',   lineName: 'M9 Atakoy–İkitelli',               type: TransportType.metro),
    RouteModel(routeId: 'M11',  lineName: 'M11 Gayrettepe–İstanbul Havalimanı', type: TransportType.metro),
    // Marmaray
    RouteModel(routeId: 'MARMARAY', lineName: 'Marmaray Gebze–Halkalı',       type: TransportType.metro),
    // Metrobüs
    RouteModel(routeId: '34B',  lineName: '34B Avcılar–Kadıköy',              type: TransportType.metrobus),
    RouteModel(routeId: '34BZ', lineName: '34BZ Avcılar–Zincirlikuyu',        type: TransportType.metrobus),
    // Tramvay
    RouteModel(routeId: 'T1',   lineName: 'T1 Kabataş–Bağcılar',             type: TransportType.tram),
    RouteModel(routeId: 'T5',   lineName: 'T5 Alibeyköy–Eminönü',            type: TransportType.tram),
    // Ekspres
    RouteModel(routeId: '500T', lineName: '500T Bağcılar–Bostancı',          type: TransportType.bus),
    RouteModel(routeId: 'E1',   lineName: 'E1 Yenikapı–Alibeyköy',           type: TransportType.bus),
    RouteModel(routeId: 'E2',   lineName: 'E2 Bostancı–Kadıköy',             type: TransportType.bus),
    RouteModel(routeId: 'E3',   lineName: 'E3 Üsküdar–Ümraniye',             type: TransportType.bus),
    RouteModel(routeId: 'E4',   lineName: 'E4 Taksim–Beşiktaş',              type: TransportType.bus),
    RouteModel(routeId: 'E5',   lineName: 'E5 Kadıköy–Bostancı',             type: TransportType.bus),
    // Otobüs - Avrupa
    RouteModel(routeId: '35',   lineName: '35 Eminönü–Bağcılar',             type: TransportType.bus),
    RouteModel(routeId: '38E',  lineName: '38E Eminönü–Esenyurt',            type: TransportType.bus),
    RouteModel(routeId: '43',   lineName: '43 Beyazıt–Güngören',             type: TransportType.bus),
    RouteModel(routeId: '45',   lineName: '45 Eminönü–Gaziosmanpaşa',        type: TransportType.bus),
    RouteModel(routeId: '47',   lineName: '47 Taksim–Sarıyer',               type: TransportType.bus),
    RouteModel(routeId: '50',   lineName: '50 Eminönü–Bahçelievler',         type: TransportType.bus),
    RouteModel(routeId: '61',   lineName: '61 Taksim–Beşiktaş',              type: TransportType.bus),
    RouteModel(routeId: '66',   lineName: '66 Taksim–Sarıyer',               type: TransportType.bus),
    RouteModel(routeId: '73',   lineName: '73 Eminönü–Sultançiftliği',       type: TransportType.bus),
    RouteModel(routeId: '80',   lineName: '80 Eminönü–Küçükköy',             type: TransportType.bus),
    // Otobüs - Anadolu
    RouteModel(routeId: '11',   lineName: '11 Üsküdar–Beykoz',               type: TransportType.bus),
    RouteModel(routeId: '12',   lineName: '12 Üsküdar–Ümraniye',             type: TransportType.bus),
    RouteModel(routeId: '14',   lineName: '14 Kadıköy–Pendik',               type: TransportType.bus),
    RouteModel(routeId: '15',   lineName: '15 Üsküdar–Bostancı',             type: TransportType.bus),
    RouteModel(routeId: '17',   lineName: '17 Kadıköy–Kartal',               type: TransportType.bus),
    RouteModel(routeId: '19',   lineName: '19 Üsküdar–Çekmeköy',             type: TransportType.bus),
    RouteModel(routeId: '22',   lineName: '22 Kadıköy–Ataşehir',             type: TransportType.bus),
    RouteModel(routeId: '25',   lineName: '25 Üsküdar–Beykoz',               type: TransportType.bus),
    RouteModel(routeId: '28',   lineName: '28 Beşiktaş–Sarıyer',             type: TransportType.bus),
    RouteModel(routeId: '30',   lineName: '30 Kadıköy–Maltepe',              type: TransportType.bus),
    RouteModel(routeId: '32',   lineName: '32 Üsküdar–Sultanbeyli',          type: TransportType.bus),
    RouteModel(routeId: '34',   lineName: '34 Kadıköy–Kartal',               type: TransportType.bus),
    RouteModel(routeId: '36',   lineName: '36 Üsküdar–Ataşehir',             type: TransportType.bus),
    RouteModel(routeId: '38',   lineName: '38 Kadıköy–Pendik',               type: TransportType.bus),
    // Vapur
    RouteModel(routeId: 'F1',   lineName: 'F1 Eminönü–Ayvansaray',           type: TransportType.bus),
    RouteModel(routeId: 'F2',   lineName: 'F2 Eminönü–Eyüp',                 type: TransportType.bus),
];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await _settings.getLanguage();
    if (!mounted) return;
    setState(() => _language = language);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrediction(String routeId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$_flaskBaseUrl/get_prediction/$routeId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final densityScore = (data['densityScore'] as num).toDouble();
        setState(() {
          _selectedPrediction = PredictionModel(
            predId:       'live_${DateTime.now().millisecondsSinceEpoch}',
            routeId:      routeId,
            densityScore: densityScore,
            confidenceScore: (data['confidenceScore'] as num? ?? 0.5).toDouble(),
            timestamp:    DateTime.now(),
          );
          _forecastPoints = List<Map<String, dynamic>>.from(
              data['forecast'] ?? []);
          _showBottomSheet = true;
        });
        await _fetchAlternativeRoutes(routeId, densityScore);
        await _checkAndSendDensityAlert(routeId, densityScore);
      } else {
        _showErrorSnackbar(_t(
            'Tahmin servisi hatasi (${response.statusCode})',
            'Prediction service error (${response.statusCode})'));
      }
    } catch (e) {
      _showErrorSnackbar(_t('Veri alınamadı: $e', 'Data could not be fetched: $e'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAlternativeRoutes(String routeId, double currentDensity) async {
    RouteModel? selected;
    for (final r in _allRoutes) {
      if (r.routeId == routeId) {
        selected = r;
        break;
      }
    }
    if (selected == null) return;
    final selectedType = selected.type;

    final candidates = _allRoutes
        .where((r) => r.type == selectedType && r.routeId != routeId)
        .take(6)
        .toList();
    if (candidates.isEmpty) return;

    setState(() => _isLoadingAlternatives = true);
    try {
      final futures = candidates.map((r) async {
        try {
          final resp = await http
              .get(Uri.parse('$_flaskBaseUrl/get_prediction/${r.routeId}'))
              .timeout(const Duration(seconds: 8));
          if (resp.statusCode != 200) return null;
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final score = (data['densityScore'] as num?)?.toDouble();
          if (score == null) return null;
          return {
            'routeId': r.routeId,
            'lineName': r.lineName,
            'densityScore': score,
          };
        } catch (_) {
          return null;
        }
      });

      final raw = await Future.wait(futures);
      final alternatives = raw
          .whereType<Map<String, dynamic>>()
          .where((m) => (m['densityScore'] as double) < currentDensity)
          .toList()
        ..sort((a, b) =>
            (a['densityScore'] as double).compareTo(b['densityScore'] as double));

      if (!mounted) return;
      setState(() => _alternativeRoutes = alternatives.take(3).toList());
    } finally {
      if (mounted) {
        setState(() => _isLoadingAlternatives = false);
      }
    }
  }

  Future<void> _fetchIncidents(String routeId) async {
    try {
      final response = await http
          .get(Uri.parse('$_flaskBaseUrl/get_incidents/$routeId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final all = List<Map<String, dynamic>>.from(data['incidents'] ?? []);
      final active = all.where((i) => i['active'] == true).toList();
      if (!mounted) return;
      setState(() => _activeIncidents = active);
      await _checkAndSendIncidentAlert(routeId, active);
    } catch (_) {
      // Incident mock akisi icin sessiz hata gecisi yeterli.
    }
  }

  Future<void> _fetchRouteStops(String routeId) async {
    try {
      final response = await http
          .get(Uri.parse('$_flaskBaseUrl/get_stops/$routeId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _showErrorSnackbar(_t(
            'Duraklar yuklenemedi (${response.statusCode})',
            'Stops could not be loaded (${response.statusCode})'));
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawStops = List<Map<String, dynamic>>.from(data['stops'] ?? []);
      if (rawStops.isEmpty) return;

      final stopMarkers = <Marker>{};
      final polylinePoints = <LatLng>[];

      for (int i = 0; i < rawStops.length; i++) {
        final stop = rawStops[i];
        final lat = (stop['lat'] as num).toDouble();
        final lng = (stop['lng'] as num).toDouble();
        final name = (stop['name'] ?? _t('Durak', 'Stop')).toString();
        final id = (stop['id'] ?? '${routeId}_$i').toString();
        final etaMin = (stop['etaMin'] as num?)?.toInt();
        final point = LatLng(lat, lng);
        polylinePoints.add(point);

        stopMarkers.add(
          Marker(
            markerId: MarkerId('stop_$id'),
            position: point,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: name,
              snippet: etaMin != null
                  ? _t('$routeId durağı • ~$etaMin dk', '$routeId stop • ~$etaMin min')
                  : _t('$routeId durağı', '$routeId stop'),
            ),
          ),
        );
      }

      setState(() {
        _markers.removeWhere((m) => m.markerId.value.startsWith('stop_'));
        _markers.addAll(stopMarkers);

        _polylines.removeWhere((p) => p.polylineId.value.startsWith('route_'));
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_$routeId'),
            points: polylinePoints,
            width: 5,
            color: Colors.blue.shade700,
          ),
        );
      });

      _fitMapToPoints(polylinePoints);
    } catch (e) {
      _showErrorSnackbar(_t('Duraklar alinamadi: $e', 'Stops could not be fetched: $e'));
    }
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _clearSelectedRouteView();
      setState(() { _searchResults = []; _showSearchResults = false; });
      return;
    }
    final results = _allRoutes
        .where((r) =>
            r.lineName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() { _searchResults = results; _showSearchResults = true; });
  }

  void _clearSelectedRouteView() {
    setState(() {
      _selectedRouteId = '';
      _showBottomSheet = false;
      _selectedPrediction = null;
      _forecastPoints = [];
      _activeIncidents = [];
      _alternativeRoutes = [];
      _markers.removeWhere((m) => m.markerId.value.startsWith('stop_'));
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('route_'));
    });
  }

  void _selectRoute(RouteModel route) {
    _searchController.text = route.lineName;
    setState(() {
      _showSearchResults = false;
      _selectedRouteId   = route.routeId;
    });
    FocusScope.of(context).unfocus();
    _fetchRouteStops(route.routeId);
    _fetchPrediction(route.routeId);
    _fetchIncidents(route.routeId);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:         Text(message),
          backgroundColor: Colors.red),
    );
  }

  Future<void> _checkAndSendDensityAlert(String routeId, double densityScore) async {
    final thresholdPct = await _settings.getDensityAlertThreshold();
    final threshold = thresholdPct / 100.0;
    if (densityScore < threshold) return;

    final user = await _fs.getUser();
    if (user == null || !user.favoriteRoutes.contains(routeId)) return;

    final last = _lastDensityAlertAt[routeId];
    final now = DateTime.now();
    if (last != null && now.difference(last).inMinutes < 20) return;

    _lastDensityAlertAt[routeId] = now;
    await _notifier.sendDensityAlert(routeId: routeId, densityScore: densityScore);
  }

  Future<void> _checkAndSendIncidentAlert(
    String routeId,
    List<Map<String, dynamic>> incidents,
  ) async {
    if (incidents.isEmpty) return;

    final user = await _fs.getUser();
    if (user == null || !user.favoriteRoutes.contains(routeId)) return;

    final now = DateTime.now();
    final last = _lastIncidentAlertAt[routeId];
    if (last != null && now.difference(last).inMinutes < 30) return;

    incidents.sort((a, b) {
      final aDelay = (a['delayMin'] as num?)?.toInt() ?? 0;
      final bDelay = (b['delayMin'] as num?)?.toInt() ?? 0;
      return bDelay.compareTo(aDelay);
    });
    final top = incidents.first;

    _lastIncidentAlertAt[routeId] = now;
    final localizedTitle = LocaleHelper.incidentTitle(top, _language);
    await _notifier.sendIncidentAlert(
      routeId: routeId,
      title: localizedTitle,
      delayMin: (top['delayMin'] as num?)?.toInt() ?? 0,
      incidentType: top['type']?.toString(),
    );
  }

  Color _densityColor(double score) {
    if (score < 0.33) return Colors.green;
    if (score < 0.66) return Colors.orange;
    return Colors.red;
  }

  IconData _densityIcon(double score) {
    if (score < 0.33) return Icons.airline_seat_recline_normal;
    if (score < 0.66) return Icons.people;
    return Icons.groups;
  }

  String _densityLabel(double score) =>
      LocaleHelper.densityLabel(score, _language);

  String _confidenceLabel(double score) =>
      LocaleHelper.confidenceLabel(score, _language);

  String _incidentSeverityLabel(String raw) =>
      LocaleHelper.incidentSeverityLabel(raw, _language);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: const CameraPosition(
                target: _istanbulCenter, zoom: 12),
            onMapCreated:          (c) => _mapController = c,
            markers:               _markers,
            polylines:             _polylines,
            myLocationEnabled:     true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled:   false,
            onTap: (_) {
              FocusScope.of(context).unfocus();
              setState(() => _showSearchResults = false);
            },
          ),

          // Arama Çubuğu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color:      Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset:     const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged:  _onSearchChanged,
                      decoration: InputDecoration(
                        hintText:   _t('Hat arayın (örn: 500T, M2)...', 'Search line (e.g. 500T, M2)...'),
                        hintStyle:  TextStyle(color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                })
                            : null,
                        border:         InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  if (_showSearchResults && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color:      Colors.black.withOpacity(0.08),
                              blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        children: _searchResults.map((route) {
                          final icon = route.type == TransportType.metro
                              ? Icons.subway
                              : Icons.directions_bus_filled;
                          return ListTile(
                            leading: Icon(icon, color: Colors.blue),
                            title:   Text(route.lineName),
                            subtitle: Text(
                                LocaleHelper.transportTypeLabel(
                                    route.type, _language)),
                            onTap: () => _selectRoute(route),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading
          if (_isLoading)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(_t('Tahmin alınıyor...', 'Fetching prediction...')),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Sheet
          if (_showBottomSheet && _selectedPrediction != null)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.36,
                minChildSize: 0.14,
                maxChildSize: 0.84,
                snap: true,
                snapSizes: const [0.14, 0.36, 0.84],
                builder: (context, scrollController) {
                  return _buildPredictionSheet(
                    _selectedPrediction!,
                    scrollController,
                  );
                },
              ),
            ),

          // Profil Butonu
          Positioned(
            top:   80,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag:         'profile',
                onPressed:       () async {
                  await Navigator.pushNamed(context, '/profile');
                  if (mounted) await _loadLanguage();
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, color: Colors.blue),
              ),
            ),
          ),

          // Bildir Butonu
          Positioned(
            right:  16,
            bottom: _showBottomSheet ? 220 : 32,
            child: FloatingActionButton.extended(
              heroTag:         'feedback',
              onPressed: () async {
                if (_selectedRouteId.isEmpty) {
                  _showErrorSnackbar(_t('Önce bir hat seçin', 'Select a line first'));
                  return;
                }
                // pushNamed'in bitmesini (sayfanın kapanmasını) bekle
               await Navigator.pushNamed(context, '/feedback', arguments: _selectedRouteId);
  
                if (mounted) await _loadLanguage();
                // Bildirim yapılıp geri dönüldüğünde, yeni oranı görmek için tahmini tekrar çek
                _fetchPrediction(_selectedRouteId);
              },
              icon:            const Icon(Icons.people_alt_outlined),
              label:           Text(_t('Bildir', 'Report')),
              backgroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSheet(
    PredictionModel prediction,
    ScrollController scrollController,
  ) {
    final color = _densityColor(prediction.densityScore);
    final icon  = _densityIcon(prediction.densityScore);
    final pct   = (prediction.densityScore * 100).round();
    final confidencePct = (prediction.confidenceScore * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow:    [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(_selectedRouteId,
                          style: const TextStyle(
                              fontSize:   20,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon:      const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showBottomSheet = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_densityLabel(prediction.densityScore),
                                style: TextStyle(
                                    fontSize:   22,
                                    fontWeight: FontWeight.bold,
                                    color:      color)),
                            Text(_t('Anlık durum', 'Current status'),
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 56, height: 56,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value:           prediction.densityScore,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation(color),
                                strokeWidth: 6,
                              ),
                              Center(
                                child: Text('$pct%',
                                    style: TextStyle(
                                        fontSize:   13,
                                        fontWeight: FontWeight.bold,
                                        color:      color)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_outlined,
                                size: 18, color: Colors.blueGrey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              _t('Güven skoru: $confidencePct%', 'Confidence score: $confidencePct%'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _confidenceLabel(prediction.confidenceScore),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: prediction.confidenceScore,
                            minHeight: 8,
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blueGrey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_forecastPoints.isNotEmpty) ...[
                    Text(_t('İleriye Tahmin', 'Forecast'),
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      Colors.grey[700])),
                    const SizedBox(height: 8),
                    Row(
                      children: _forecastPoints.map((f) {
                        final fscore =
                            (f['densityScore'] as num).toDouble();
                        final fcolor = _densityColor(fscore);
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:        fcolor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: fcolor.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(_t('+${f['minutesAhead']} dk', '+${f['minutesAhead']} min'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:    Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text(_densityLabel(fscore),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize:   12,
                                        fontWeight: FontWeight.w600,
                                        color:      fcolor)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_activeIncidents.isNotEmpty) ...[
                    Text(_t('Aktif Olaylar', 'Active Incidents'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    ..._activeIncidents.take(2).map((incident) {
                      final delay = (incident['delayMin'] as num?)?.toInt() ?? 0;
                      final title = LocaleHelper.incidentTitle(incident, _language);
                      final severity = _incidentSeverityLabel(
                        (incident['severity'] ?? '').toString(),
                      );
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red.shade400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$title • ${_t("Seviye", "Severity")}: $severity • '
                                '${_t("Gecikme", "Delay")}: ~$delay ${_t("dk", "min")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  Text(_t('Alternatif Hat Önerileri', 'Alternative Route Suggestions'),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  if (_isLoadingAlternatives)
                    const LinearProgressIndicator()
                  else if (_alternativeRoutes.isEmpty)
                    Text(_t('Daha iyi alternatif bulunamadı', 'No better alternatives found'),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13))
                  else
                    ..._alternativeRoutes.map((alt) {
                      final score = (alt['densityScore'] as double);
                      final c = _densityColor(score);
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alt_route, color: c, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${alt['routeId']} • ${_densityLabel(score)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Text(_t('Yolcu Bildirimleri', 'Passenger Reports'),
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      Colors.grey[700])),
                  const SizedBox(height: 8),
                  _buildCrowdsourceStream(_selectedRouteId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdsourceStream(String routeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('routeId', isEqualTo: routeId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(_t('Henüz bildirim yok', 'No report yet'),
              style: TextStyle(color: Colors.grey[500], fontSize: 13));
        }
        final feedbacks = snapshot.data!.docs
            .map((d) => FeedbackModel.fromFirestore(d))
            .toList();
        final emptyCnt =
            feedbacks.where((f) => f.status == DensityStatus.empty).length;
        final standingCnt = feedbacks
            .where((f) => f.status == DensityStatus.standing)
            .length;
        final fullCnt =
            feedbacks.where((f) => f.status == DensityStatus.full).length;

        return Row(
          children: [
            _statusChip(_t('Boş', 'Empty'),    emptyCnt,    Colors.green),
            const SizedBox(width: 8),
            _statusChip(_t('Ayakta', 'Standing'), standingCnt, Colors.orange),
            const SizedBox(width: 8),
            _statusChip(_t('Dolu', 'Full'),   fullCnt,     Colors.red),
          ],
        );
      },
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label ($count)',
          style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.15),
      side:            BorderSide(color: color.withOpacity(0.3)),
      padding:         EdgeInsets.zero,
    );
  }
}
