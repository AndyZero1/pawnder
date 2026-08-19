import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'popup.dart';
import 'add_clinic_form.dart';
import 'add_lost_pet_form.dart';
import 'add_event_form.dart';
import 'add_gem_form.dart';
import 'events_screen.dart';

enum AddingMode { none, clinic, lostPet, event, gem }

class MapScreen extends StatefulWidget {
  final List<dynamic> myPets;
  final String userName;

  const MapScreen({super.key, required this.myPets, required this.userName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLocation;
  final MapController _mapController = MapController();

  List<Marker> customMarkers = [];
  List<Map<String, dynamic>> activeGems = [];
  List<Map<String, dynamic>> activeEvents = [];

  AddingMode _currentAddMode = AddingMode.none;
  StreamSubscription<Position>? _positionStream;
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();
    fetchLocationsFromServer();

    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      bool sAstersCeva = false;

      activeEvents.removeWhere((eveniment) {
        if (eveniment['expiraLa'] != null &&
            now.isAfter(eveniment['expiraLa'])) {
          sAstersCeva = true;
          return true;
        }
        return false;
      });

      if (sAstersCeva && mounted) {
        setState(() {});
      }
    });
  }

  Future<void> fetchLocationsFromServer() async {
    double minLat = 43.60;
    double maxLat = 48.25;
    double minLon = 20.26;
    double maxLon = 29.72;

    final String apiUrl =
        'http://10.0.2.2:8000/api/map/locations/?min_lat=$minLat&max_lat=$maxLat&min_lon=$minLon&max_lon=$maxLon';

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> serverData = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            activeEvents.clear();
            activeGems.clear();
            customMarkers.clear();

            for (var item in serverData) {
              final latLng = LatLng(item['latitude'], item['longitude']);
              final tipLocatie = item['type'];

              if (tipLocatie == 'PET_FRIENDLY') {
                activeEvents.add({
                  'id': item['id'],
                  'point': latLng,
                  'nume': item['title'],
                  'dataStart': item['start_date'] ?? 'Date not specified',
                  'oraEnd': item['end_time'] ?? '',
                  'detalii':
                      item['description'] ?? 'Tap to join for details',
                  'expiraLa': item['end_time'] != null
                      ? DateTime.parse(item['end_time'])
                      : DateTime.now().add(const Duration(days: 30)),
                });
              } else if (tipLocatie == 'HIDDEN_GEM') {
                activeGems.add({
                  'id': item['id'],
                  'point': latLng,
                  'name': item['title'],
                });
              } else if (tipLocatie == 'VET_CLINIC') {
                customMarkers.add(
                  Marker(
                    point: latLng,
                    width: 55,
                    height: 55,
                    child: GestureDetector(
                      onTap: () {
                        showVetPopup(context, {
                          'id': item['id'],
                          'nume': item['title'],
                          'detalii': item['description'] ?? 'No details',
                          'recenzii': <Map<String, dynamic>>[],
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_hospital,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (tipLocatie == 'MISSING_PET') {
                customMarkers.add(
                  Marker(
                    point: latLng,
                    width: 55,
                    height: 55,
                    child: GestureDetector(
                      onTap: () {
                        showLostPetPopup(
                          context,
                          item['title'],
                          'Unspecified',
                          item['description'] ?? '',
                          null,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.pets,
                            color: Colors.orange,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          });
        }
      }
    } catch (e) {
      
    }
  }

  void _startLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(
              () => currentLocation = LatLng(
                position.latitude,
                position.longitude,
              ),
            );
          }
        });
    Position initialPos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        currentLocation = LatLng(initialPos.latitude, initialPos.longitude);
        _mapController.move(currentLocation!, 15.0);
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
                title: const Text(
                  'Lost Pet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentAddMode = AddingMode.lostPet);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.event, color: Colors.white),
                ),
                title: const Text(
                  'Organize Event',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentAddMode = AddingMode.event);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.local_hospital, color: Colors.white),
                ),
                title: const Text(
                  'Register Clinic',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentAddMode = AddingMode.clinic);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.diamond, color: Colors.white),
                ),
                title: const Text(
                  'Hide a Treasure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentAddMode = AddingMode.gem);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final romaniaBounds = LatLngBounds(
      const LatLng(43.60, 20.26),
      const LatLng(48.25, 29.72),
    );
    const Distance distanceCalculator = Distance();

    List<Marker> visibleGemMarkers = [];
    if (currentLocation != null) {
      for (var gem in activeGems) {
        if (distanceCalculator.as(
              LengthUnit.Meter,
              currentLocation!,
              gem['point'],
            ) <=
            50) {
          visibleGemMarkers.add(
            Marker(
              point: gem['point'],
              width: 65,
              height: 65,
              child: GestureDetector(
                onTap: () async {
                 
                  final success = await showHiddenGemPopup(
                    context,
                    gem['name'],
                    gem['id'],
                  );
                  if (success == true) {
                    setState(() => activeGems.remove(gem));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.diamond, color: Colors.amber, size: 35),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    List<Marker> eventMarkers = activeEvents.map((ev) {
      return Marker(
        point: ev['point'],
        width: 55,
        height: 55,
        child: GestureDetector(
          onTap: () => showEventPopup(
            context,
            ev['id'].toString(),
            ev['nume'],
            ev['dataStart'] ?? '',
            ev['oraEnd'] ?? '',
            ev['detalii'],
            widget.myPets,
            widget.userName,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purpleAccent, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.event, color: Colors.purpleAccent, size: 28),
            ),
          ),
        ),
      );
    }).toList();

    Color getFabColor() {
      switch (_currentAddMode) {
        case AddingMode.lostPet:
          return Colors.orange;
        case AddingMode.event:
          return Colors.purpleAccent;
        case AddingMode.clinic:
          return Colors.redAccent;
        case AddingMode.gem:
          return Colors.amber;
        default:
          return Colors.blueAccent;
      }
    }

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "btn_locate",
            onPressed: () {
              if (currentLocation != null)
                _mapController.move(currentLocation!, 16.0);
            },
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.my_location, color: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "btn_add",
            onPressed: () => _showActionMenu(context),
            backgroundColor: getFabColor(),
            elevation: 6,
            icon: Icon(
              _currentAddMode != AddingMode.none ? Icons.touch_app : Icons.add,
              color: Colors.white,
            ),
            label: Text(
              _currentAddMode != AddingMode.none ? 'Tap on the map...' : 'Add',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(45.9432, 24.9668),
              initialZoom: 15.0,
              minZoom: 7.5,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(bounds: romaniaBounds),
              onTap: (tapPosition, tappedPoint) async {
                if (_currentAddMode == AddingMode.clinic) {
                
                  final clinicData = await showAddClinicForm(
                    context,
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                  );
                  if (!context.mounted || clinicData == null) {
                    setState(() => _currentAddMode = AddingMode.none);
                    return;
                  }
                  final dynamicClinicData = Map<String, dynamic>.from(
                    clinicData,
                  );
                  dynamicClinicData['recenzii'] = <Map<String, dynamic>>[];
                  setState(() {
                    customMarkers.add(
                      Marker(
                        point: tappedPoint,
                        width: 55,
                        height: 55,
                        child: GestureDetector(
                          onTap: () => showVetPopup(context, dynamicClinicData),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.redAccent,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    _currentAddMode = AddingMode.none;
                  });
                } else if (_currentAddMode == AddingMode.lostPet) {
                 
                  final petData = await showAddLostPetForm(
                    context,
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                  );
                  if (!context.mounted || petData == null) {
                    setState(() => _currentAddMode = AddingMode.none);
                    return;
                  }
                  setState(() {
                    customMarkers.add(
                      Marker(
                        point: tappedPoint,
                        width: 55,
                        height: 55,
                        child: GestureDetector(
                          onTap: () => showLostPetPopup(
                            context,
                            petData['nume']!,
                            petData['telefon']!,
                            petData['detalii']!,
                            petData['poza'] as Uint8List?,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.orange,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.pets,
                                color: Colors.orange,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    _currentAddMode = AddingMode.none;
                  });
                } else if (_currentAddMode == AddingMode.event) {
                 
                  final eventData = await showAddEventForm(
                    context,
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                  );
                  if (!context.mounted || eventData == null) {
                    setState(() => _currentAddMode = AddingMode.none);
                    return;
                  }
                  setState(() {
                    activeEvents.add({'point': tappedPoint, ...eventData});
                    _currentAddMode = AddingMode.none;
                  });
                } else if (_currentAddMode == AddingMode.gem) {

                  final gemName = await showAddGemForm(
                    context,
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                  );
                  if (!context.mounted || gemName == null) {
                    setState(() => _currentAddMode = AddingMode.none);
                    return;
                  }
                  setState(() {
                    activeGems.add({'point': tappedPoint, 'name': gemName});
                    _currentAddMode = AddingMode.none;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pawndar',
              ),
              MarkerLayer(
                markers: [
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...customMarkers,
                  ...visibleGemMarkers,
                  ...eventMarkers,
                ],
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8D7DF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Pawnder',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.event_note,
                              color: Colors.purple,
                              size: 26,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EventsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
