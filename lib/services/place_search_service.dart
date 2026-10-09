import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cairo_metro_app/data/metro_network.dart';
import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:cairo_metro_app/services/nlp_search_service.dart';
import 'package:get/get.dart';

class PlaceItem {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? fullAddress;
  final String? arabicName;
  final List<String> keywords;

  const PlaceItem({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.fullAddress,
    this.arabicName,
    this.keywords = const [],
  });
}

class PlaceSearchService {
  /// Well-known Cairo landmarks, districts, hospitals, and universities (offline database)
  static const List<PlaceItem> cairoPlaces = [
    // Major Cairo & Giza Districts (Within Metro Range)
    PlaceItem(
      name: 'Nasr City',
      category: 'District (East Cairo)',
      latitude: 30.0558,
      longitude: 31.3412,
      arabicName: 'مدينة نصر',
      keywords: ['مكرم عبيد', 'عباس العقاد', 'nasr city'],
    ),
    PlaceItem(
      name: 'Heliopolis (Masr El Gedida)',
      category: 'District (East Cairo)',
      latitude: 30.0886,
      longitude: 31.3283,
      arabicName: 'مصر الجديدة',
      keywords: ['الكوربة', 'روكسي', 'heliopolis', 'masr el gedida'],
    ),
    PlaceItem(
      name: 'Maadi',
      category: 'District (South Cairo)',
      latitude: 29.9598,
      longitude: 31.2589,
      arabicName: 'المعادي',
      keywords: ['معادي', 'دجلة', 'maadi', 'el maadi'],
    ),
    PlaceItem(
      name: 'Zamalek',
      category: 'District (Gezira Island)',
      latitude: 30.0617,
      longitude: 31.2195,
      arabicName: 'الزمالك',
      keywords: ['جزيرة الزمالك', 'zamalek', 'el zamalek'],
    ),
    PlaceItem(
      name: 'Dokki',
      category: 'District (Giza)',
      latitude: 30.0385,
      longitude: 31.2124,
      arabicName: 'الدقي',
      keywords: ['دقي', 'ميدان المساحة', 'مصدق', 'dokki', 'el dokki'],
    ),
    PlaceItem(
      name: 'Mohandessin',
      category: 'District (Giza)',
      latitude: 30.0526,
      longitude: 31.2014,
      arabicName: 'المهندسين',
      keywords: ['جامعة الدول', 'لبنان', 'mohandessin'],
    ),
    PlaceItem(
      name: 'Al-Manial',
      category: 'District (Roda Island)',
      latitude: 30.0270,
      longitude: 31.2270,
      arabicName: 'المنيل',
      keywords: ['منيل الروضة', 'manial'],
    ),
    PlaceItem(
      name: 'Downtown (Wust El Balad)',
      category: 'District (Central Cairo)',
      latitude: 30.0488,
      longitude: 31.2405,
      arabicName: 'وسط البلد',
      keywords: ['وسط القاهرة', 'طلعت حرب', 'downtown', 'wust el balad'],
    ),
    PlaceItem(
      name: 'Shubra',
      category: 'District (North Cairo)',
      latitude: 30.0769,
      longitude: 31.2464,
      arabicName: 'شبرا',
      keywords: ['شبرا مصر', 'shubra'],
    ),
    PlaceItem(
      name: 'Abbassia',
      category: 'District (Central Cairo)',
      latitude: 30.0678,
      longitude: 31.2825,
      arabicName: 'العباسية',
      keywords: ['عباسية', 'الدمرداش', 'abbassia'],
    ),
    PlaceItem(
      name: 'Sayeda Zeinab',
      category: 'District (Historic Cairo)',
      latitude: 30.0305,
      longitude: 31.2394,
      arabicName: 'السيدة زينب',
      keywords: ['السيده زينب', 'sayeda zeinab'],
    ),
    PlaceItem(
      name: 'Helwan',
      category: 'District (South Cairo)',
      latitude: 29.8494,
      longitude: 31.3342,
      arabicName: 'حلوان',
      keywords: ['helwan'],
    ),
    PlaceItem(
      name: 'Mokattam',
      category: 'District (East Cairo)',
      latitude: 30.0156,
      longitude: 31.3025,
      arabicName: 'المقطم',
      keywords: ['مقطم', 'mokattam'],
    ),
    PlaceItem(
      name: 'Faisal & Haram',
      category: 'District (Giza)',
      latitude: 30.0033,
      longitude: 31.1800,
      arabicName: 'فيصل والهرم',
      keywords: ['الهرم', 'فيصل', 'شارع فيصل', 'شارع الهرم', 'faisal', 'haram'],
    ),
    PlaceItem(
      name: 'Imbaba',
      category: 'District (Giza)',
      latitude: 30.0744,
      longitude: 31.2100,
      arabicName: 'إمبابة',
      keywords: ['امبابة', 'imbaba'],
    ),
    PlaceItem(
      name: 'Agouza',
      category: 'District (Giza)',
      latitude: 30.0570,
      longitude: 31.2140,
      arabicName: 'العجوزة',
      keywords: ['عجوزة', 'agouza'],
    ),

    // Major Hospitals & Medical Centers
    PlaceItem(
      name: 'Kasr Al Ainy Hospital',
      category: 'Hospital (Manial)',
      latitude: 30.0305,
      longitude: 31.2291,
      arabicName: 'مستشفى القصر العيني',
      keywords: ['قصر العيني', 'kasr al ainy', 'kasr el aini'],
    ),
    PlaceItem(
      name: 'Children\'s Cancer Hospital 57357',
      category: 'Hospital (Sayeda Zeinab)',
      latitude: 30.0217,
      longitude: 31.2361,
      arabicName: 'مستشفى 57357',
      keywords: ['مستشفى سرطان الاطفال', '57357', 'cancer hospital'],
    ),
    PlaceItem(
      name: 'Ain Shams University Hospital (Demerdash)',
      category: 'Hospital (Abbassia)',
      latitude: 30.0705,
      longitude: 31.2783,
      arabicName: 'مستشفيات جامعة عين شمس الدمرداش',
      keywords: ['الدمرداش', 'مستشفى الدمرداش', 'demerdash'],
    ),
    PlaceItem(
      name: 'Al Salam International Hospital',
      category: 'Hospital (Maadi)',
      latitude: 29.9839,
      longitude: 31.2300,
      arabicName: 'مستشفى السلام الدولي بالمعادي',
      keywords: ['السلام الدولي', 'as-salam international'],
    ),
    PlaceItem(
      name: 'Cleopatra Hospital',
      category: 'Hospital (Heliopolis)',
      latitude: 30.0903,
      longitude: 31.3289,
      arabicName: 'مستشفى كليوباترا',
      keywords: ['كليوباترا', 'cleopatra'],
    ),

    // Attractions & Culture
    PlaceItem(
      name: 'Cairo Tower',
      category: 'Landmark (Zamalek)',
      latitude: 30.0459,
      longitude: 31.2243,
      arabicName: 'برج القاهرة',
      keywords: ['برج القاهره', 'cairo tower'],
    ),
    PlaceItem(
      name: 'The Egyptian Museum (Tahrir)',
      category: 'Museum (Downtown)',
      latitude: 30.0478,
      longitude: 31.2336,
      arabicName: 'المتحف المصري بالتحرير',
      keywords: ['المتحف المصري', 'egyptian museum'],
    ),
    PlaceItem(
      name: 'National Museum of Egyptian Civilization (NMEC)',
      category: 'Museum (Fustat)',
      latitude: 30.0078,
      longitude: 31.2483,
      arabicName: 'متحف الحضارة بالفسطاط',
      keywords: ['متحف الحضارة', 'nmec', 'fustat museum'],
    ),
    PlaceItem(
      name: 'Khan El-Khalili',
      category: 'Historic Market (Old Cairo)',
      latitude: 30.0477,
      longitude: 31.2625,
      arabicName: 'خان الخليلي',
      keywords: ['الحسين', 'شارع المعز', 'khan el khalili'],
    ),
    PlaceItem(
      name: 'Al-Azhar Mosque & Park',
      category: 'Park & Mosque (Old Cairo)',
      latitude: 30.0409,
      longitude: 31.2655,
      arabicName: 'حديقة الأزهر وجامع الأزهر',
      keywords: ['حديقة الازهر', 'جامع الازهر', 'azhar park'],
    ),
    PlaceItem(
      name: 'Cairo Opera House',
      category: 'Culture (Gezira)',
      latitude: 30.0425,
      longitude: 31.2238,
      arabicName: 'دار الأوبرا المصرية',
      keywords: ['الاوبرا', 'opera house'],
    ),
    PlaceItem(
      name: 'Baron Empain Palace',
      category: 'Heritage (Heliopolis)',
      latitude: 30.0867,
      longitude: 31.3303,
      arabicName: 'قصر البارون إمبان',
      keywords: ['قصر البارون', 'baron palace'],
    ),
    PlaceItem(
      name: 'Merryland Park (Heliopolis)',
      category: 'Park & Attraction (Heliopolis)',
      latitude: 30.0980,
      longitude: 31.3190,
      arabicName: 'حديقة الميريلاند',
      keywords: [
        'الميرلاند', 'الميريلاند', 'حديقة الميرلاند', 'حديقة الميريلاند',
        'منتزه الميريلاند', 'ميرلاند', 'ميريلاند', 'merryland', 'maryland',
        'merryland park', 'مصر الجديدة', 'روكسي'
      ],
    ),
    PlaceItem(
      name: 'Korba & Roxy',
      category: 'Historic Hub (Heliopolis)',
      latitude: 30.0910,
      longitude: 31.3250,
      arabicName: 'الكوربة وميدان روكسي',
      keywords: ['الكوربة', 'روكسي', 'ميدان روكسي', 'korba', 'roxy'],
    ),
    PlaceItem(
      name: 'Giza Pyramids & Sphinx',
      category: 'Wonders (Giza)',
      latitude: 29.9792,
      longitude: 31.1342,
      arabicName: 'أهرامات الجيزة وأبو الهول',
      keywords: ['الاهرامات', 'ابو الهول', 'pyramids', 'giza pyramids'],
    ),
    PlaceItem(
      name: 'Grand Egyptian Museum (GEM)',
      category: 'Museum (Giza)',
      latitude: 29.9942,
      longitude: 31.1197,
      arabicName: 'المتحف المصري الكبير',
      keywords: ['المتحف الكبير', 'gem', 'grand egyptian museum'],
    ),
    PlaceItem(
      name: 'Cairo Citadel (Salah El-Din)',
      category: 'Historic Fort (Old Cairo)',
      latitude: 30.0299,
      longitude: 31.2611,
      arabicName: 'قلعة صلاح الدين الأيوبي',
      keywords: ['القلعة', 'قلعة القاهرة', 'citadel'],
    ),
    PlaceItem(
      name: 'Coptic Cairo & Hanging Church',
      category: 'Religious (Mar Girgis)',
      latitude: 30.0053,
      longitude: 31.2301,
      arabicName: 'مجمع الأديان والكنيسة المعلقة',
      keywords: ['الكنيسة المعلقة', 'ماري جرجس', 'coptic cairo'],
    ),

    // Universities
    PlaceItem(
      name: 'Cairo University Campus',
      category: 'Education (Giza)',
      latitude: 30.0276,
      longitude: 31.2089,
      arabicName: 'جامعة القاهرة',
      keywords: ['جامعه القاهره', 'cairo university'],
    ),
    PlaceItem(
      name: 'Ain Shams University (Abbassia)',
      category: 'Education (Abbassia)',
      latitude: 30.0772,
      longitude: 31.2853,
      arabicName: 'جامعة عين شمس',
      keywords: ['جامعه عين شمس', 'ain shams university'],
    ),
    PlaceItem(
      name: 'Helwan University Campus',
      category: 'Education (Helwan)',
      latitude: 29.8689,
      longitude: 31.3203,
      arabicName: 'جامعة حلوان',
      keywords: ['جامعه حلوان', 'helwan university'],
    ),
    PlaceItem(
      name: 'Al-Azhar University (Nasr City)',
      category: 'Education (Nasr City)',
      latitude: 30.0558,
      longitude: 31.3142,
      arabicName: 'جامعة الأزهر',
      keywords: ['جامعه الازهر', 'al azhar university'],
    ),
    PlaceItem(
      name: 'American University in Cairo (Tahrir)',
      category: 'Education (Tahrir)',
      latitude: 30.0433,
      longitude: 31.2372,
      arabicName: 'الجامعة الأمريكية بالتحرير',
      keywords: ['الجامعه الامريكيه', 'auc'],
    ),

    // Shopping, Business & Transit Hubs
    PlaceItem(
      name: 'Citystars Mall',
      category: 'Shopping (Nasr City)',
      latitude: 30.0733,
      longitude: 31.3467,
      arabicName: 'مول سيتي ستارز',
      keywords: ['سيتي ستارز', 'citystars'],
    ),
    PlaceItem(
      name: 'Cairo Festival City',
      category: 'Shopping (New Cairo)',
      latitude: 30.0325,
      longitude: 31.4130,
      arabicName: 'كايرو فيستيفال سيتي',
      keywords: ['التجمع الخامس', 'cfc', 'cairo festival city'],
    ),
    PlaceItem(
      name: 'Mall of Arabia',
      category: 'Shopping (6th of October)',
      latitude: 30.0075,
      longitude: 30.9733,
      arabicName: 'مول العرب',
      keywords: ['مول العرب 6 اكتوبر', 'mall of arabia'],
    ),
    PlaceItem(
      name: 'Mall of Egypt',
      category: 'Shopping (6th of October)',
      latitude: 29.9725,
      longitude: 31.0183,
      arabicName: 'مول مصر',
      keywords: ['مول مصر 6 اكتوبر', 'mall of egypt'],
    ),
    PlaceItem(
      name: 'Tahrir Square',
      category: 'Public Square (Downtown)',
      latitude: 30.0444,
      longitude: 31.2357,
      arabicName: 'ميدان التحرير',
      keywords: ['التحرير', 'tahrir'],
    ),
    PlaceItem(
      name: 'Ramses Railway Station',
      category: 'Transit Hub (Ramses)',
      latitude: 30.0625,
      longitude: 31.2464,
      arabicName: 'محطة مصر رمسيس',
      keywords: ['محطة رمسيس', 'ramses station'],
    ),
    PlaceItem(
      name: 'Cairo International Stadium',
      category: 'Sports (Nasr City)',
      latitude: 30.0694,
      longitude: 31.3122,
      arabicName: 'ستاد القاهرة الدولي',
      keywords: ['استاد القاهره', 'cairo stadium'],
    ),
    PlaceItem(
      name: 'Orman Botanical Garden',
      category: 'Park (Giza)',
      latitude: 30.0294,
      longitude: 31.2133,
      arabicName: 'حديقة الأورمان',
      keywords: ['حديقه الاورمان', 'orman garden'],
    ),
    PlaceItem(
      name: 'Giza Zoo',
      category: 'Attraction (Giza)',
      latitude: 30.0239,
      longitude: 31.2133,
      arabicName: 'حديقة حيوان الجيزة',
      keywords: ['حديقه الحيوان', 'giza zoo'],
    ),
    PlaceItem(
      name: 'Al-Ahly SC (Gezira)',
      category: 'Sports Club (Zamalek)',
      latitude: 30.0433,
      longitude: 31.2208,
      arabicName: 'النادي الأهلي الجزيرة',
      keywords: ['الاهلي', 'اهلي الجزيرة', 'al ahly'],
    ),
    PlaceItem(
      name: 'Zamalek SC',
      category: 'Sports Club (Mohandessin)',
      latitude: 30.0575,
      longitude: 31.2064,
      arabicName: 'نادي الزمالك',
      keywords: ['الزمالك نادي', 'ميت عقبة', 'zamalek club'],
    ),
  ];

  /// Calculates geographic distance in kilometers using the Haversine formula
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Live Geocoding Search: Uses NLP entity extraction and queries OpenStreetMap Nominatim
  /// with intelligent fallback and NLP semantic relevance scoring.
  static Future<List<PlaceItem>> geocodePlaces(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return cairoPlaces;

    final entity = NlpSearchService.extractDestinationEntity(clean);

    // Quick match from local database first with NLP
    final localMatches = searchPlaces(clean);

    // If entity has less than 2 characters, local search is sufficient
    if (entity.length < 2) return localMatches;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 7);

    try {
      final candidates = NlpSearchService.generateQueryCandidates(entity);
      final liveResults = <PlaceItem>[];

      Future<void> fetchCandidate(String queryStr, {bool useViewbox = true}) async {
        try {
          final encodedQuery = Uri.encodeComponent(queryStr);
          final urlStr = useViewbox
              ? 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=10&countrycodes=eg&viewbox=30.60,30.60,32.10,29.50'
              : 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=10&countrycodes=eg';

          final req = await client.getUrl(Uri.parse(urlStr));
          req.headers.set('User-Agent', 'CairoMetroApp/1.0 (contact: info@cairometro.app; flutter)');
          req.headers.set('Accept-Language', 'ar,en');

          final resp = await req.close().timeout(const Duration(seconds: 6));
          if (resp.statusCode == 200) {
            final body = await resp.transform(utf8.decoder).join();
            final List<dynamic> data = jsonDecode(body);
            for (final item in data) {
              final lat = double.tryParse(item['lat']?.toString() ?? '');
              final lon = double.tryParse(item['lon']?.toString() ?? '');
              if (lat == null || lon == null) continue;
              if (lat < 29.4 || lat > 30.7 || lon < 30.5 || lon > 32.2) continue;

              final displayName = (item['display_name'] ?? '').toString();
              final parts = displayName.split(',').map((s) => s.trim()).toList();
              final mainName = (item['name'] != null && item['name'].toString().trim().isNotEmpty)
                  ? item['name'].toString().trim()
                  : (parts.isNotEmpty ? parts.first : entity);

              final subName = parts.length > 2
                  ? '${parts[1]}, ${parts[2]}'
                  : (parts.length > 1 ? parts[1] : 'Greater Cairo');

              final type = item['type'] ?? item['class'] ?? 'Location';
              final formattedCategory = '${_formatType(type.toString())} • $subName';

              if (!liveResults.any((p) => p.name.toLowerCase() == mainName.toLowerCase())) {
                liveResults.add(
                  PlaceItem(
                    name: mainName,
                    category: formattedCategory,
                    latitude: lat,
                    longitude: lon,
                    fullAddress: displayName,
                  ),
                );
              }
            }
          }
        } catch (_) {}
      }

      // Stage 1: Query primary extracted entity
      await fetchCandidate(candidates.first);

      // Stage 2: If no results, query spelling/prefix candidate (e.g. الميريلاند)
      if (liveResults.isEmpty && candidates.length > 1) {
        await fetchCandidate(candidates[1]);
      }

      // Stage 3: If still no results, query with explicit Cairo specification
      if (liveResults.isEmpty && !entity.toLowerCase().contains('cairo') && !entity.contains('قاهرة')) {
        await fetchCandidate('$entity, Cairo, Egypt', useViewbox: false);
      }

        final combined = <PlaceItem>[...localMatches];
        for (final live in liveResults) {
          if (!combined.any((p) => p.name.toLowerCase() == live.name.toLowerCase())) {
            combined.add(live);
          }
        }

        // Rank all candidates using NLP similarity to the user's destination entity
        combined.sort((a, b) {
          final scoreA = NlpSearchService.calculateSimilarity(
            entity,
            a.name,
            aliases: [a.category, if (a.arabicName != null) a.arabicName!, ...a.keywords],
          );
          final scoreB = NlpSearchService.calculateSimilarity(
            entity,
            b.name,
            aliases: [b.category, if (b.arabicName != null) b.arabicName!, ...b.keywords],
          );
          return scoreB.compareTo(scoreA);
        });

        // Filter out low confidence matches to prevent garbage results
        final confident = combined.where((p) {
          final score = NlpSearchService.calculateSimilarity(
            entity,
            p.name,
            aliases: [p.category, if (p.arabicName != null) p.arabicName!, ...p.keywords],
          );
          return score >= 0.25;
        }).toList();

        return confident;
    } catch (_) {
      // Graceful fallback to local matches upon network exception or timeout
    } finally {
      client.close();
    }

    return localMatches;
  }

  static String _formatType(String rawType) {
    if (rawType.isEmpty) return 'Place';
    final capitalized = rawType[0].toUpperCase() + rawType.substring(1).replaceAll('_', ' ');
    return capitalized;
  }

  /// Searches the offline dataset using NLP Arabic & English normalization & fuzzy similarity matching
  static List<PlaceItem> searchPlaces(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return cairoPlaces;

    final entity = NlpSearchService.extractDestinationEntity(clean);
    final scored = <({PlaceItem place, double score})>[];

    for (final place in cairoPlaces) {
      final score = NlpSearchService.calculateSimilarity(
        entity,
        place.name,
        aliases: [
          place.category,
          if (place.arabicName != null) place.arabicName!,
          ...place.keywords,
        ],
      );
      if (score >= 0.25) {
        scored.add((place: place, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    // Never return default cairoPlaces for non-empty search queries
    return scored.map((e) => e.place).toList();
  }

  /// Finds the metro station with the minimum distance to a given place
  static ({Station station, double distanceKm, String placeName})? findNearestStationToPlace({
    required PlaceItem place,
    required MetroNetwork network,
  }) {
    return findNearestStationToCoordinates(
      latitude: place.latitude,
      longitude: place.longitude,
      placeName: place.name,
      network: network,
    );
  }

  /// Finds the nearest metro station to any arbitrary latitude & longitude
  static ({Station station, double distanceKm, String placeName})? findNearestStationToCoordinates({
    required double latitude,
    required double longitude,
    required String placeName,
    required MetroNetwork network,
  }) {
    final coordService = Get.find<CoordinateService>();
    final stations = network.allStations;
    if (stations.isEmpty) return null;

    Station? bestStation;
    double minDistance = double.infinity;

    for (final station in stations) {
      double? sLat = station.latitude;
      double? sLng = station.longitude;

      // Fallback to CoordinateService if station lat/lng is null
      if (sLat == null || sLng == null) {
        final coords = coordService.coordinatesGrabber(station.id);
        if (coords != null) {
          sLat = coords.lat;
          sLng = coords.lng;
        }
      }

      if (sLat != null && sLng != null) {
        final dist = calculateDistanceKm(
          lat1: latitude,
          lon1: longitude,
          lat2: sLat,
          lon2: sLng,
        );
        if (dist < minDistance) {
          minDistance = dist;
          bestStation = station;
        }
      }
    }

    if (bestStation == null) return null;

    return (
      station: bestStation,
      distanceKm: double.parse(minDistance.toStringAsFixed(2)),
      placeName: placeName,
    );
  }
}
