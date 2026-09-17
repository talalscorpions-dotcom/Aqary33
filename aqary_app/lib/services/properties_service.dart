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

  /// POST /properties — seller-only (enforced server-side by requireRole).
  /// New listings start out pending verification (BR-PROP-06), matching
  /// how a sign-up submission works.
  Future<Property> createListing({
    required String category,
    String? listingType,
    String? propertyType,
    required String title,
    required num price,
    required String region,
    required String city,
    String? locationDetail,
    num? areaSqm,
    int? bedrooms,
    int? bathrooms,
  }) async {
    final body = await ApiClient.instance.post('/properties', {
      'category': category,
      'listingType': listingType,
      'propertyType': propertyType,
      'title': title,
      'price': price,
      'region': region,
      'city': city,
      'locationDetail': locationDetail,
      'areaSqm': areaSqm,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
    });
    return Property.fromJson(body);
  }
}
