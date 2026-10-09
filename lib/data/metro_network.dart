import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:get/get.dart';

class MetroNetwork {
  final List<String> line1Names = [
    "Helwan", "Ain Helwan", "Helwan University", 
    "Wadi Hof", "Hadayek Helwan", "El-Maasara", "Tora El-Asmant", "Kozzika", 
    "Tora El-Balad", "Sakanat El-Maadi", "Maadi", "Hadayek El-Maadi", 
    "Dar El-Salam", "El-Zahraa", "Mar Girgis", "El-Malek El-Saleh", 
    "Al-Sayeda Zeinab", "Saad Zaghloul", "Sadat", "Gamal AbdElNasser", 
    "Orabi", "Al-Shohadaa", "Ghamra", "El-Demerdash", "Manshiet El-Sadr", 
    "Kobri El-Qobba", "Hammamat El-Qobba", "Saray El-Qobba", "Hadayek El-Zaitoun", 
    "Helmiyet El-Zaitoun", "El-Matareyya", "Ain Shams", "Ezbet El-Nakhl", 
    "El-Marg", "New El-Marg"
  ];

  final List<String> line2Names = [
    "El Mounib", "Sakiat Mekki", "Omm El Misryeen", "Giza", "Faisal", 
    "Cairo University", "El Bohoth", "Dokki", "Opera", "Sadat", 
    "Mohamed Naguib", "Attaba", "Al-Shohadaa", "Massara", "Road El-Farag", 
    "St. Teresa", "Khalafawy", "Mezallat", "Kolleyyet El-Zeraa", 
    "Shubra El-Kheima"
  ];

  final List<String> line3Trunk = [
    "Adly Mansour", "Haykestep", "Omar Ibn El Khattab", "Qubaa", 
    "Hesham Barakat", "El Nozha", "El Shams Club", "Alf Masken", 
    "Heliopolis", "Haroun", "Al-Ahram", "Koleyet El-Banat", "Stadium", 
    "Fair Zone", "Abbassiya", "Abdou Pasha", "El-Geish", "Bab El Shaariya", 
    "Attaba", "Gamal AbdElNasser", "Maspero", "Safaa Hegazy", "Kit Kat"
  ];

  final List<String> line3North = [
    "Sudan", "Imbaba", "El-Bohy", "El-Qawmia", "Ring Road", "Rod El Farag Corridor"//rodelfaragcorridor
  ];

  final List<String> line3South = [
    "El-Tawfikiya", "Wadi El Nile", "Gamaat El-Dowal", "Bulaq El Dakrour", "Cairo University"
  ];

  final Map<Station, List<Station>> graph = {};

  final Map<String, Station> _registry = {};

  Station _stationMaker(String stationName, int lineNumber) {
  String nameToID = stationName.replaceAll(" ", "").replaceAll("-", "").toLowerCase();

  if (_registry.containsKey(nameToID)) {
    Station existingStation = _registry[nameToID]!;
    if (!existingStation.lines.contains(lineNumber)) {
      existingStation.lines.add(lineNumber);
    }
    return existingStation;
  } else {
    final coordinateService = Get.find<CoordinateService>();
    final coords = coordinateService.coordinatesGrabber(nameToID);

    Station newStation = Station(
      id: nameToID, 
      name: stationName, 
      lines: [lineNumber],
      latitude: coords?.lat,
      longitude: coords?.lng,
    );

    _registry[nameToID] = newStation;
    graph[newStation] = [];
    return newStation;
  }
}

  void _buildLine(List<String> names, int lineNumber)
  {
    List<Station> stations = [];
    for(String name in names)
    {
      stations.add(_stationMaker(name, lineNumber));
    } 
    for(int i = 0 ; i < stations.length ; i++)
    {
      Station current = stations[i];
      if(i > 0)
      {
        if(!graph[current]!.contains(stations[i - 1]))
        {
          graph[current]!.add(stations[i - 1]);
        }
      }
      if(i < stations.length - 1)
      {
        if(!graph[current]!.contains(stations[i + 1]))
        {
          graph[current]!.add(stations[i + 1]);
        }
      }
    }
  }

  void buildNetwork() {
    _buildLine(line1Names, 1);
    _buildLine(line2Names, 2);
    _buildLine(line3Trunk, 3);
    _buildLine(line3North, 3);
    _buildLine(line3South, 3);
    Station kitkat = _registry["kitkat"]!;
    Station sudan = _registry["sudan"]!;
    Station tawfikiya = _registry["eltawfikiya"]!;
    graph[kitkat]!.add(sudan);
    graph[sudan]!.add(kitkat);
    graph[kitkat]!.add(tawfikiya);
    graph[tawfikiya]!.add(kitkat); 
  }

  Station? findStationByName(String input)
  {
    String key = input.replaceAll(" ", "").replaceAll("-", "").toLowerCase();
    return _registry[key];
  }

  List<Station> get allStations {
    final list = _registry.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}