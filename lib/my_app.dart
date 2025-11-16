import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoadingPOI = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pointsOfInterest = [];
  double _centerLat = 10.762622;
  double _centerLon = 106.660172;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterMapApp'},
      );

      if (response.statusCode != 200) {
        throw ("Status code is different from 200");
      }

      final List<dynamic> data = json.decode(response.body);
      // print(data);
      setState(() {
        _searchResults = data.map((e) => e as Map<String, dynamic>).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _fetchNearbyByPOI(double lat, double lon) async {
    setState(() {
      _isLoadingPOI = true;
    });

    try {
      final radius = 1000;
      final query =
          """
[out:json];
(
  node["amenity"~"restaurant|cafe|school|university|hospital"](around:$radius,$lat,$lon);
  node["tourism"~"hotel|museum"](around:$radius,$lat,$lon);
  node["shop"](around:$radius,$lat,$lon);
);
out body 5;
""";

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {"data": query},
      );

      if (response.statusCode != 200) {
        throw ("Failed to fetch POI: ${response.statusCode}");
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> elements = data["elements"] ?? [];

      setState(() {
        _pointsOfInterest = elements.map((e) {
          return {
            "lat": e["lat"],
            "lon": e["lon"],
            "name": e["tags"]?["name"] ?? "Unknown",
            "type":
                e["tags"]?["amenity"] ??
                e["tags"]?["tourism"] ??
                e["tags"]?["shop"] ??
                "POI",
          };
        }).toList();
        _isLoadingPOI = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPOI = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching POI: $e')));
      }
    }
  }

  void _moveToLocation(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 16.5);
    setState(() {
      _searchResults.clear();
      _searchController.clear();
      _centerLat = lat;
      _centerLon = lon;
    });
    _fetchNearbyByPOI(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.762622, 106.660172), // Ho Chi Minh City
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.openstreetmap_api',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_centerLat, _centerLon),
                    child: Icon(
                      Icons.location_on,
                      color: const Color.fromARGB(255, 255, 1, 1),
                      size: 40,
                    ),
                  ),

                  ..._pointsOfInterest.map((e) {
                    return Marker(
                      point: LatLng(e["lat"], e["lon"]),
                      child: Icon(
                        Icons.location_on,
                        color: const Color.fromARGB(255, 56, 5, 240),
                        size: 30,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 200,
            child: Column(
              children: [
                SizedBox(
                  width: 800,
                  height: 50,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        size: 30,
                        color: Colors.pink[100],
                      ),
                      hintText: "Enter a location",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.clear, color: Colors.pink[100]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                });
                              },
                            ),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 400,
                    width: 750,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return Card(
                          color: Colors.red[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              location["name"]!,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              location["display_name"]!,
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              final double lat = double.parse(location["lat"]);
                              final double lon = double.parse(location["lon"]);
                              _moveToLocation(lat, lon);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          if (_pointsOfInterest.isNotEmpty)
            Positioned(
              top: 180,
              right: 80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.pink[200],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Nearby POIs',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pointsOfInterest.length,
                        itemBuilder: (context, index) {
                          final poi = _pointsOfInterest[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              poi['name'],
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              poi['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () {
                              _mapController.move(
                                LatLng(poi['lat'], poi['lon']),
                                18.0,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoadingPOI)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 15),
                    Text('Loading nearby POIs...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
