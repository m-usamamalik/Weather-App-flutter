import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/place.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlaceEnricher
// ─────────────────────────────────────────────────────────────────────────────

/// Maps raw JSONPlaceholder photo entries to real travel destinations.
///
/// JSONPlaceholder (`/photos`) returns synthetic data (random Lorem Ipsum
/// titles, placeholder image URLs).  [PlaceEnricher.enrich] replaces those
/// values with curated travel data (name, country, description, coordinates,
/// and a real Unsplash photo) while keeping the API-provided [id] and
/// [albumId] so pagination and favouriting still work correctly.
///
/// The 24 curated entries cycle via modulo (`index % _placeData.length`) so
/// the first 24 API results each map to a unique destination, and any further
/// pages cycle back through the list — acceptable for a demo.
class PlaceEnricher {
  static final List<Map<String, dynamic>> _placeData = [
    {
      'name': 'Lake Tekapo',
      'country': 'New Zealand',
      'description':
          'Lake Tekapo is known for its crystal clear waters and the iconic Church of the Good Shepherd. It is part of the Aoraki Mackenzie International Dark Sky Reserve, making it a perfect spot for stargazing.',
      'lat': -44.0047,
      'lon': 170.4772,
      'image': 'https://images.unsplash.com/photo-1507699622108-4be3abd695ad?w=800&q=80',
    },
    {
      'name': 'Santorini',
      'country': 'Greece',
      'description':
          'Santorini is a stunning volcanic island in the Cyclades group of the Greek islands. It is famous for its dramatic views, gorgeous sunsets from Oia, and the unique blue-domed white-washed houses.',
      'lat': 36.3932,
      'lon': 25.4615,
      'image': 'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800&q=80',
    },
    {
      'name': 'Kyoto Temple',
      'country': 'Japan',
      'description':
          'Kyoto, once the capital of Japan, is a city on the island of Honshu. It\'s famous for its numerous classical Buddhist temples, gardens, imperial palaces, Shinto shrines, and traditional wooden houses.',
      'lat': 35.0116,
      'lon': 135.7681,
      'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',
    },
    {
      'name': 'Banff National Park',
      'country': 'Canada',
      'description':
          'Banff National Park is Canada\'s oldest national park, established in 1885 in the Rocky Mountains. The park encompasses mountains, glaciers, ice fields, dense coniferous forest, and alpine landscapes.',
      'lat': 51.4968,
      'lon': -115.9281,
      'image': 'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=800&q=80',
    },
    {
      'name': 'Machu Picchu',
      'country': 'Peru',
      'description':
          'Machu Picchu is a 15th-century Inca citadel situated on a mountain ridge above the Sacred Valley. It is the most familiar icon of Inca civilization and one of the most famous ruins in the world.',
      'lat': -13.1631,
      'lon': -72.5450,
      'image': 'https://images.unsplash.com/photo-1587595431973-160d0d163571?w=800&q=80',
    },
    {
      'name': 'Maldives',
      'country': 'Maldives',
      'description':
          'The Maldives is a tropical paradise in the Indian Ocean, composed of 26 ring-shaped atolls with over 1,000 coral islands. Known for its stunning turquoise waters, white sandy beaches, and luxurious overwater villas.',
      'lat': 3.2028,
      'lon': 73.2207,
      'image': 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800&q=80',
    },
    {
      'name': 'Swiss Alps',
      'country': 'Switzerland',
      'description':
          'The Swiss Alps are a major natural feature of Switzerland. They stretch across about 65% of the country\'s surface area. Home to iconic peaks like the Matterhorn and Jungfrau, offering world-class skiing and hiking.',
      'lat': 46.8182,
      'lon': 8.2275,
      'image': 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',
    },
    {
      'name': 'Bali Rice Terraces',
      'country': 'Indonesia',
      'description':
          'The rice terraces of Bali are a UNESCO World Heritage site showcasing the traditional Balinese irrigation system known as subak. These emerald-green terraces offer breathtaking views and insight into centuries-old farming.',
      'lat': -8.4095,
      'lon': 115.1889,
      'image': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&q=80',
    },
    {
      'name': 'Northern Lights',
      'country': 'Iceland',
      'description':
          'Iceland is one of the best places in the world to witness the Aurora Borealis. The dancing lights in shades of green, pink, and violet create an unforgettable spectacle against the Arctic sky.',
      'lat': 64.9631,
      'lon': -19.0208,
      'image': 'https://images.unsplash.com/photo-1483347756197-71ef80e95f73?w=800&q=80',
    },
    {
      'name': 'Taj Mahal',
      'country': 'India',
      'description':
          'The Taj Mahal is an ivory-white marble mausoleum on the right bank of the river Yamuna. It was commissioned in 1631 by Mughal emperor Shah Jahan to house the tomb of his favourite wife, Mumtaz Mahal.',
      'lat': 27.1751,
      'lon': 78.0421,
      'image': 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800&q=80',
    },
    {
      'name': 'Grand Canyon',
      'country': 'USA',
      'description':
          'The Grand Canyon is a steep-sided canyon carved by the Colorado River in Arizona. It is 277 miles long, up to 18 miles wide, and over a mile deep, showcasing layers of colorful rock revealing millions of years of geological history.',
      'lat': 36.1069,
      'lon': -112.1129,
      'image': 'https://images.unsplash.com/photo-1474044159687-1ee9f3a51722?w=800&q=80',
    },
    {
      'name': 'Great Barrier Reef',
      'country': 'Australia',
      'description':
          'The Great Barrier Reef is the world\'s largest coral reef system, stretching over 2,300 kilometers. It supports a stunning diversity of marine life and is visible from outer space.',
      'lat': -18.2871,
      'lon': 147.6992,
      'image': 'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=800&q=80',
    },
    {
      'name': 'Petra',
      'country': 'Jordan',
      'description':
          'Petra is a historical and archaeological city famous for its rock-cut architecture and water conduit system. Established as the capital of the Nabataean Kingdom, it\'s a UNESCO World Heritage Site and one of the New Seven Wonders.',
      'lat': 30.3285,
      'lon': 35.4444,
      'image': 'https://images.unsplash.com/photo-1579606032821-4e6161c81571?w=800&q=80',
    },
    {
      'name': 'Amalfi Coast',
      'country': 'Italy',
      'description':
          'The Amalfi Coast is a 50-kilometer stretch of coastline along the Sorrentine Peninsula in southern Italy. Its dramatic cliffs, pastel-colored fishing villages, and terraced vineyards make it one of Italy\'s most popular destinations.',
      'lat': 40.6333,
      'lon': 14.6029,
      'image': 'https://images.unsplash.com/photo-1534113414509-0eec2bfb493f?w=800&q=80',
    },
    {
      'name': 'Angkor Wat',
      'country': 'Cambodia',
      'description':
          'Angkor Wat is the largest religious monument in the world, originally constructed as a Hindu temple dedicated to the god Vishnu. It gradually transformed into a Buddhist temple and remains a symbol of Cambodia.',
      'lat': 13.4125,
      'lon': 103.8670,
      'image': 'https://images.unsplash.com/photo-1569580750075-9643ca2ef894?w=800&q=80',
    },
    {
      'name': 'Cappadocia',
      'country': 'Turkey',
      'description':
          'Cappadocia is a semi-arid region in central Turkey, known for its distinctive fairy chimneys, cave dwellings, and hot air balloon rides. The unique landscape was formed by volcanic eruptions millions of years ago.',
      'lat': 38.6431,
      'lon': 34.8289,
      'image': 'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?w=800&q=80',
    },
    {
      'name': 'Victoria Falls',
      'country': 'Zimbabwe',
      'description':
          'Victoria Falls, known locally as "The Smoke That Thunders," is one of the largest and most famous waterfalls in the world. Located on the border of Zambia and Zimbabwe, it spans over 1.7 kilometers.',
      'lat': -17.9243,
      'lon': 25.8572,
      'image': 'https://images.unsplash.com/photo-1534502746224-4d7eb7bbed59?w=800&q=80',
    },
    {
      'name': 'Fjords of Norway',
      'country': 'Norway',
      'description':
          'Norway\'s fjords are narrow inlets of the sea between high cliffs, carved by glacial erosion. The western fjords, especially Geirangerfjord and Nærøyfjord, are UNESCO World Heritage Sites known for their stunning beauty.',
      'lat': 61.3715,
      'lon': 6.2500,
      'image': 'https://images.unsplash.com/photo-1507272931001-fc06c17e4f43?w=800&q=80',
    },
    {
      'name': 'Lake Bled',
      'country': 'Slovenia',
      'description':
          'Lake Bled is a glacial lake in the Julian Alps. The small island in the center with its pilgrimage church and the medieval castle perched on cliffs above the lake create one of Europe\'s most picturesque scenes.',
      'lat': 46.3625,
      'lon': 14.0940,
      'image': 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800&q=80',
    },
    {
      'name': 'Lake Louise',
      'country': 'Canada',
      'description':
          'Lake Louise is a glacial lake within Banff National Park in Alberta, Canada. Known for its turquoise color derived from glacial rock flour, it is surrounded by towering peaks and is a popular destination year-round.',
      'lat': 51.4254,
      'lon': -116.1773,
      'image': 'https://images.unsplash.com/photo-1509023464722-18d996393ca8?w=800&q=80',
    },
    {
      'name': 'Lake Kawaguchi',
      'country': 'Japan',
      'description':
          'Lake Kawaguchi is one of the Fuji Five Lakes located at the northern foot of Mount Fuji. It offers some of the most iconic views of Mt. Fuji, especially during cherry blossom season and autumn.',
      'lat': 35.5163,
      'lon': 138.7520,
      'image': 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=800&q=80',
    },
    {
      'name': 'Dubrovnik',
      'country': 'Croatia',
      'description':
          'Dubrovnik is a city on the Adriatic Sea in southern Croatia, known for its distinctive Old Town enclosed in massive stone walls. Often called the "Pearl of the Adriatic," it gained worldwide fame as a filming location for Game of Thrones.',
      'lat': 42.6507,
      'lon': 18.0944,
      'image': 'https://images.unsplash.com/photo-1555990793-da11153b2473?w=800&q=80',
    },
    {
      'name': 'Patagonia',
      'country': 'Argentina',
      'description':
          'Patagonia is a sparsely populated region at the southern end of South America, shared between Argentina and Chile. Known for its dramatic landscapes including glaciers, mountains, and vast steppe-like plains.',
      'lat': -49.3233,
      'lon': -73.2453,
      'image': 'https://images.unsplash.com/photo-1531794180-1c48e1ba8c03?w=800&q=80',
    },
    {
      'name': 'Zhangjiajie',
      'country': 'China',
      'description':
          'Zhangjiajie National Forest Park is famous for its towering sandstone pillar formations, which inspired the floating mountains in the movie Avatar. The park features glass bridges and spectacular canyon views.',
      'lat': 29.3249,
      'lon': 110.4343,
      'image': 'https://images.unsplash.com/photo-1518709779341-56cf4535e94b?w=800&q=80',
    },
  ];

  /// Merges [apiData] (the raw JSONPlaceholder entry) with curated travel info
  /// chosen by [index] mod the length of [_placeData].
  static Place enrich(Map<String, dynamic> apiData, int index) {
    final placeInfo = _placeData[index % _placeData.length];
    return Place(
      id: apiData['id'] ?? index,
      albumId: apiData['albumId'] ?? 1,
      title: placeInfo['name'] as String,
      imageUrl: placeInfo['image'] as String,
      thumbnailUrl: placeInfo['image'] as String,
      location: placeInfo['name'] as String,
      country: placeInfo['country'] as String,
      description: placeInfo['description'] as String,
      latitude: (placeInfo['lat'] as num).toDouble(),
      longitude: (placeInfo['lon'] as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlaceApiService
// ─────────────────────────────────────────────────────────────────────────────

/// HTTP client for fetching place data.
///
/// Uses [JSONPlaceholder](https://jsonplaceholder.typicode.com/photos) as a
/// free, stable mock REST API.  The raw response is enriched by [PlaceEnricher]
/// so the app displays real travel destinations with proper imagery.
///
/// An injectable [http.Client] is accepted so unit tests can pass a mock client
/// without making real network calls.
class PlaceApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  final http.Client _client;

  PlaceApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a page of places starting at offset `(page-1) * limit`.
  ///
  /// Throws an [Exception] on non-200 status codes so [PlaceRepositoryImpl]
  /// can catch it and fall back to the local cache.
  Future<List<Place>> fetchPlaces({int page = 1, int limit = 20}) async {
    final start = (page - 1) * limit;
    final response = await _client.get(
      Uri.parse('$_baseUrl/photos?_start=$start&_limit=$limit'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.asMap().entries.map((entry) {
        return PlaceEnricher.enrich(
          entry.value as Map<String, dynamic>,
          start + entry.key,
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch places: ${response.statusCode}');
    }
  }

  /// Fetches a single photo record and enriches it to a [Place].
  Future<Place> fetchPlaceById(int id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/photos/$id'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PlaceEnricher.enrich(data as Map<String, dynamic>, id - 1);
    } else {
      throw Exception('Failed to fetch place: ${response.statusCode}');
    }
  }
}
