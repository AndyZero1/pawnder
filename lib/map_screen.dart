import 'dart:ui';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'popup.dart';
import 'add_clinic_form.dart';
import 'add_lost_pet_form.dart';
import 'add_event_form.dart';
import 'add_gem_form.dart';

enum AddingMode { none, clinic, lostPet, event, gem }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLocation;
  final MapController _mapController = MapController();

  List<Marker> customMarkers = []; // Clinici și animale pierdute
  List<Map<String, dynamic>> activeGems = []; // Comori
  List<Map<String, dynamic>> activeEvents = []; // NOU: Evenimente temporare

  AddingMode _currentAddMode = AddingMode.none;
  StreamSubscription<Position>? _positionStream;
  Timer? _cleanupTimer; // NOU: Robotul de curățenie

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();

    // NOU: La fiecare 30 de secunde, verificăm dacă un eveniment a expirat
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      bool sAstersCeva = false;

      // Căutăm prin evenimente
      activeEvents.removeWhere((eveniment) {
        if (now.isAfter(eveniment['expiraLa'])) {
          sAstersCeva = true; // Am găsit unul expirat!
          return true; // Se șterge din listă
        }
        return false;
      });

      // Dacă am șters ceva din culise, îi dăm un refresh hărții ca să dispară și de pe ecran
      if (sAstersCeva) {
        setState(() {});
      }
    });
  }

  void _startLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;
    }
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((Position position) {
          setState(
            () =>
                currentLocation = LatLng(position.latitude, position.longitude),
          );
        });
    Position initialPos = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(initialPos.latitude, initialPos.longitude);
      _mapController.move(currentLocation!, 15.0);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _cleanupTimer?.cancel(); // Oprim ceasul la ieșire
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
                  'Animal Pierdut',
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
                  'Organizare Eveniment',
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
                  'Înregistrează Clinică',
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
                  'Ascunde o Comoară',
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
                onTap: () {
                  showHiddenGemPopup(context, gem['name']);
                  setState(() => activeGems.remove(gem));
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

    // NOU: Transformăm lista cu evenimente active în Markere pentru hartă
    List<Marker> eventMarkers = activeEvents.map((ev) {
      return Marker(
        point: ev['point'],
        width: 55,
        height: 55,
        child: GestureDetector(
          onTap: () => showEventPopup(
            context,
            ev['nume'],
            ev['dataStart'],
            ev['oraEnd'],
            ev['detalii'],
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
              _currentAddMode != AddingMode.none ? 'Atinge harta...' : 'Adaugă',
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
                  final clinicData = await showAddClinicForm(context);
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
                  final petData = await showAddLostPetForm(context);
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
                }
                // NOU: ADĂUGĂM EVENIMENTUL ÎN LISTA ACTIVĂ
                else if (_currentAddMode == AddingMode.event) {
                  final eventData = await showAddEventForm(context);
                  if (!context.mounted || eventData == null) {
                    setState(() => _currentAddMode = AddingMode.none);
                    return;
                  }

                  setState(() {
                    activeEvents.add({
                      'point': tappedPoint,
                      ...eventData, // Adaugă nume, dataStart, oraEnd, detalii, expiraLa
                    });
                    _currentAddMode = AddingMode.none;
                  });
                } else if (_currentAddMode == AddingMode.gem) {
                  final gemName = await showAddGemForm(context);
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
                  ...eventMarkers, // <--- Afișăm pe hartă lista de evenimente!
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
                    color: Colors.pink.shade100,
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
                          'Pawndar',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 22,
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
