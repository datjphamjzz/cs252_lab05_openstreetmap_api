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
  bool _isLoadingWeather = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pointsOfInterest = [];
  Map<String, dynamic>? _weatherData;
  double _centerLat = 10.762622;
  double _centerLon = 106.660172;
  String _locationName = "Ho Chi Minh City";

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

  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Replace with your OpenWeatherMap API key
      const apiKey = '5ee19ad194ad2ec02b056a51c3d712c8';
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw ("Failed to fetch weather: ${response.statusCode}");
      }

      final Map<String, dynamic> data = json.decode(response.body);

      setState(() {
        _weatherData = data;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching weather: $e')));
      }
    }
  }

  void _moveToLocation(double lat, double lon, String name) {
    _mapController.move(LatLng(lat, lon), 16.5);
    setState(() {
      _searchResults.clear();
      _searchController.clear();
      _centerLat = lat;
      _centerLon = lon;
      _locationName = name;
    });
    _fetchNearbyByPOI(lat, lon);
    _fetchWeather(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Map with search overlay
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(10.762622, 106.660172),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.openstreetmap_api',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_centerLat, _centerLon),
                          child: Icon(
                            Icons.location_on,
                            color: const Color.fromARGB(255, 255, 0, 72),
                            size: 40,
                          ),
                        ),
                        ..._pointsOfInterest.map((e) {
                          return Marker(
                            point: LatLng(e["lat"], e["lon"]),
                            child: Icon(
                              Icons.location_on,
                              color: const Color(0xFF8B5A8B),
                              size: 30,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Search bar overlay
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: 24,
                              color: Color(0xFFF4BCCC),
                            ),
                            hintText: "Search for a location...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFF4BCCC),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Color(0xFFF4BCCC),
                                    ),
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
                          margin: EdgeInsets.only(top: 8),
                          constraints: BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final location = _searchResults[index];
                              return ListTile(
                                title: Text(
                                  location["name"] ??
                                      location["display_name"] ??
                                      "Unknown",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  location["display_name"] ?? "",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  final double lat = double.parse(
                                    location["lat"],
                                  );
                                  final double lon = double.parse(
                                    location["lon"],
                                  );
                                  _moveToLocation(
                                    lat,
                                    lon,
                                    location["name"] ??
                                        location["display_name"] ??
                                        "Selected Location",
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right sidebar
          Container(
            width: 350,
            color: Colors.grey[100],
            child: Column(
              children: [
                // Upper half - Weather
                Expanded(child: _buildWeatherSection()),
                Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                // Lower half - POIs
                Expanded(child: _buildPOISection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Color(0xFFF4BCCC)),
            child: Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingWeather
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFFF4BCCC)),
                  )
                : _weatherData == null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Select a location to view weather',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildWeatherContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weatherData == null) return SizedBox();

    final temp = _weatherData!['main']?['temp']?.toStringAsFixed(1) ?? '--';
    final feelsLike =
        _weatherData!['main']?['feels_like']?.toStringAsFixed(1) ?? '--';
    final humidity = _weatherData!['main']?['humidity']?.toString() ?? '--';
    final description = _weatherData!['weather']?[0]?['description'] ?? 'N/A';
    final weatherMain = _weatherData!['weather']?[0]?['main'] ?? '';
    final windSpeed =
        _weatherData!['wind']?['speed']?.toStringAsFixed(1) ?? '--';

    IconData weatherIcon = Icons.wb_sunny;
    if (weatherMain.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud;
    } else if (weatherMain.toLowerCase().contains('rain')) {
      weatherIcon = Icons.water_drop;
    } else if (weatherMain.toLowerCase().contains('clear')) {
      weatherIcon = Icons.wb_sunny;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _locationName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(weatherIcon, size: 80, color: Color(0xFFF4BCCC)),
                SizedBox(height: 12),
                Text(
                  '$temp°C',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildWeatherDetail('Feels Like', '$feelsLike°C', Icons.thermostat),
          SizedBox(height: 12),
          _buildWeatherDetail('Humidity', '$humidity%', Icons.water_drop),
          SizedBox(height: 12),
          _buildWeatherDetail('Wind Speed', '$windSpeed m/s', Icons.air),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF4BCCC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFF4BCCC), size: 20),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOISection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Color(0xFFF4BCCC)),
            child: Row(
              children: [
                Icon(Icons.place, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Nearby POIs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingPOI
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFFF4BCCC)),
                  )
                : _pointsOfInterest.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Select a location to view nearby POIs',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: _pointsOfInterest.length,
                    itemBuilder: (context, index) {
                      final poi = _pointsOfInterest[index];
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF4BCCC).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getPOIIcon(poi['type']),
                            color: Color(0xFFF4BCCC),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          poi['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          poi['type'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
    );
  }

  IconData _getPOIIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'school':
      case 'university':
        return Icons.school;
      case 'hospital':
        return Icons.local_hospital;
      case 'hotel':
        return Icons.hotel;
      case 'museum':
        return Icons.museum;
      default:
        return Icons.store;
    }
  }
}
