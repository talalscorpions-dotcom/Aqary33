import '../models/property.dart';
import 'api_client.dart';

/// GET /properties in aqary_backend — same query shape the mock version
/// simulated (see the doc comment on PropertyResultsScreen).
class PropertiesService {
  PropertiesService._();
  static final PropertiesService instance = PropertiesService._();

  Future<List<Property>> fetchListings({
    required String category,
    String? listingType,
    required String propertyType,
  }) async {
    final body = await ApiClient.instance.get('/properties', query: {
      'category': category,
      'listing_type': listingType,
      'property_type': propertyType,
    });
    final results = body['results'] as List<dynamic>? ?? const [];
    return results
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
