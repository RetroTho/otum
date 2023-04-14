import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

List<Widget> hourlyTemps = [];

String getDate() {
  DateTime now = DateTime.now();
  String year = now.year.toString();
  String month = now.month.toString().padLeft(2, '0');
  String day = now.day.toString().padLeft(2, '0');
  String date = '$year-$month-$day';
  debugPrint(date);
  return date;
}

String buildURL(String url, Map<String, dynamic> params) {
  List<String> keys = params.keys.toList();
  int keysLength = keys.length;
  bool first = true;
  for (int i = 0; i < keysLength; i++) {
    if (first) {
      first = false;
    } else {
      url += '&';
    }
    if (params[keys[i]] is String) {
      url = '$url${keys[i]}=${params[keys[i]]}';
    } else {
      int valsLength = params[keys[i]].length;
      first = true;
      for (int j = 0; j < valsLength; j++) {
        if (first) {
          first = false;
        } else {
          url += '&';
        }
        url = '$url${keys[i]}=${params[keys[i]][j]}';
      }
    }
  }
  debugPrint(url);
  return url;
}

List<Widget> buildHourly(Weather weather) {
  List<Widget> hourlyWidgets = [];
  int hours = weather.hourlyTemp.length;
    debugPrint('HOURS: $hours');
    for (int i = 0; i < hours; i++) {
      hourlyWidgets.add(Text('${weather.hourlyTime[i].substring(11)}: ${weather.hourlyTemp[i]}°'));
    }
  return hourlyWidgets;
}

Future<Weather> fetchWeather() async {
  // La Verne, CA (91750) coords (lat,lon): 34.14776,-117.75206
  String url = 'https://api.open-meteo.com/v1/forecast?';
  String date = getDate();
  Map<String, dynamic> params = {
    'latitude': '34.148',
    'longitude': '-117.752',
    'current_weather': 'true',
    'daily': <String>['temperature_2m_min', 'temperature_2m_max'],
    'hourly': 'temperature_2m',
    'temperature_unit': 'fahrenheit',
    'windspeed_unit': 'mph',
    'precipitation_unit': 'inch',
    'timeformat': 'iso8601',
    'past_days': '0',
    'forecast_days': '3',
    'start_date': date,
    'end_date': date,
    'timezone': 'America%2FLos_Angeles',
  };

  final response = await http.get(Uri.parse(buildURL(url, params)));

  debugPrint('API Called');
  if (response.statusCode == 200) {
    Weather result = Weather.fromJson(jsonDecode(response.body));
    hourlyTemps = buildHourly(result);
    return result;
  } else {
    throw Exception('Failed to get weather');
  }
}

class Weather {
  final double temperature;
  final double dailyMin;
  final double dailyMax;
  final List hourlyTemp;
  final List hourlyTime;

  const Weather({
    required this.temperature,
    required this.dailyMin,
    required this.dailyMax,
    required this.hourlyTemp,
    required this.hourlyTime,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: json['current_weather']['temperature'],
      dailyMin: json['daily']['temperature_2m_min'][0],
      dailyMax: json['daily']['temperature_2m_max'][0],
      hourlyTemp: json['hourly']['temperature_2m'],
      hourlyTime: json['hourly']['time'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late Future<Weather> futureWeather;

  @override
  void initState() {
    super.initState();
    futureWeather = fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otum'),
      ),
      body: Center(
        child: FutureBuilder<Weather>(
          future: futureWeather,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${snapshot.data!.temperature}°',
                    style: const TextStyle(
                      fontSize: 50,
                    ),
                  ),
                  Text(
                    'Low: ${snapshot.data!.dailyMin}°',
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'High: ${snapshot.data!.dailyMax}°',
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      child: Column(
                        children: hourlyTemps,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        
                        futureWeather = fetchWeather();
                      });
                    },
                    child: const Text('Refresh'),
                  )
                ],
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
