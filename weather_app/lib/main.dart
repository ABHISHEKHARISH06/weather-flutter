import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;
  bool isLocationLoading = false;

  // Replace with your OpenWeatherMap API key
  final String apiKey = '2acafb9ba3431ecf247eee6b7e9fc7ce';

  @override
  void initState() {
    super.initState();
    // App starts with blank screen - no default city
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() {
      isLocationLoading = true;
      errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled';
          isLocationLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permissions are denied';
            isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permissions are permanently denied';
          isLocationLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch weather using coordinates
      await fetchWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to get location: $e';
        isLocationLoading = false;
      });
    }
  }

  Future<void> fetchWeatherByCoordinates(double lat, double lon) async {
    if (apiKey == 'YOUR_API_KEY_HERE') {
      setState(() {
        errorMessage = 'Please add your OpenWeatherMap API key';
        isLocationLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
          isLocationLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch weather data';
          isLoading = false;
          isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch weather data';
        isLoading = false;
        isLocationLoading = false;
      });
    }
  }
  Future<void> fetchWeather(String cityName) async {
    if (apiKey == 'YOUR_API_KEY_HERE') {
      setState(() {
        errorMessage = 'Please add your OpenWeatherMap API key';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'City not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch weather data';
        isLoading = false;
      });
    }
  }

  String getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  Color getBackgroundColor() {
    if (weatherData == null) return Colors.blue.shade400;
    
    final weatherMain = weatherData!['weather'][0]['main'].toString().toLowerCase();
    switch (weatherMain) {
      case 'clear':
        return Colors.orange.shade300;
      case 'clouds':
        return Colors.grey.shade400;
      case 'rain':
      case 'drizzle':
        return Colors.blue.shade600;
      case 'thunderstorm':
        return Colors.grey.shade700;
      case 'snow':
        return Colors.blue.shade200;
      default:
        return Colors.blue.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              getBackgroundColor(),
              getBackgroundColor().withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Location and Search Bar Row
                Row(
                  children: [
                    // Location Button
                    Container(
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: isLocationLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              )
                            : Icon(Icons.my_location, color: Colors.blue),
                        onPressed: isLocationLoading ? null : fetchWeatherByLocation,
                        tooltip: 'Use current location',
                      ),
                    ),
                    // Search Bar
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search city...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send, color: Colors.blue),
                              onPressed: () {
                                if (_searchController.text.isNotEmpty) {
                                  fetchWeather(_searchController.text);
                                }
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              fetchWeather(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40),
                
                // Weather Content
                Expanded(
                  child: (isLoading || isLocationLoading)
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : weatherData != null
                              ? WeatherDisplay(weatherData: weatherData!)
                              : Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherDisplay extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDisplay({Key? key, required this.weatherData}) : super(key: key);

  String getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final temp = weatherData['main']['temp'].round();
    final feelsLike = weatherData['main']['feels_like'].round();
    final humidity = weatherData['main']['humidity'];
    final windSpeed = weatherData['wind']['speed'];
    final cityName = weatherData['name'];
    final country = weatherData['sys']['country'];
    final weatherMain = weatherData['weather'][0]['main'];
    final weatherDescription = weatherData['weather'][0]['description'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // City Name
        Text(
          '$cityName, $country',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        
        SizedBox(height: 20),
        
        // Weather Icon
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            getWeatherIcon(weatherMain),
            style: TextStyle(fontSize: 80),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Temperature
        Text(
          '${temp}°C',
          style: TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w100,
          ),
        ),
        
        // Weather Description
        Text(
          weatherDescription.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        
        SizedBox(height: 40),
        
        // Weather Details
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              WeatherDetail(
                icon: Icons.thermostat,
                label: 'Feels like',
                value: '${feelsLike}°C',
              ),
              WeatherDetail(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${humidity}%',
              ),
              WeatherDetail(
                icon: Icons.air,
                label: 'Wind',
                value: '${windSpeed} m/s',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const WeatherDetail({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}