import 'package:flutter/material.dart';

/// Mirrors the `properties` table in the Properties Module Architecture
/// document: category / listing_type / property_type drive every filtered
/// results screen through one shared query shape.
enum VerificationStatus { pending, verified, rejected }

class Property {
  final String id;
  final String category; // residential | commercial | agriculture | industrial
  final String? listingType; // rent | sale
  final String propertyType; // villa | apartment | land | office | shop | farmhouse
  final String title;
  final double price;
  final String currency;
  final String wilayat;
  final String city;
  final double? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final VerificationStatus status;
  final List<Color> imageGradient; // stand-in for real photos in this scaffold

  const Property({
    required this.id,
    required this.category,
    required this.propertyType,
    required this.title,
    required this.price,
    required this.wilayat,
    required this.city,
    required this.status,
    required this.imageGradient,
    this.listingType,
    this.currency = 'OMR',
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
  });

  /// Maps a row from `GET /properties` in aqary_backend. Oman's admin
  /// levels don't line up 1:1 with this model's naming: the backend's
  /// `city` column is documented as "Wilayat" (matches [wilayat] here),
  /// while its `region` column is the broader Governorate and has no
  /// field on this model yet. `location_detail` — a free-text
  /// neighbourhood like "Al Khuwair" — is the closest match to what this
  /// model calls [city].
  factory Property.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final locationDetail = json['location_detail'] as String?;
    return Property(
      id: id,
      category: json['category'] as String,
      listingType: json['listing_type'] as String?,
      propertyType: json['property_type'] as String? ?? '',
      title: json['title'] as String,
      price: _parseNum(json['price']) ?? 0,
      currency: json['currency'] as String? ?? 'OMR',
      wilayat: json['city'] as String? ?? '',
      city: (locationDetail != null && locationDetail.trim().isNotEmpty)
          ? locationDetail
          : (json['city'] as String? ?? ''),
      areaSqm: _parseNum(json['area_sqm']),
      bedrooms: _parseInt(json['bedrooms']),
      bathrooms: _parseInt(json['bathrooms']),
      // GET /properties (search) doesn't select verification_status at all
      // — every row it returns is already filtered to 'verified' server
      // side, so that's the correct default when the key is absent.
      // GET /properties/:id (detail) does select it via `SELECT *`.
      status: json.containsKey('verification_status')
          ? _statusFromString(json['verification_status'] as String?)
          : VerificationStatus.verified,
      imageGradient: _gradientFor(id),
    );
  }

  String get formattedPrice {
    final isRent = listingType == 'rent';
    final amount = price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return isRent ? '$currency $amount/mo' : '$currency $amount';
  }
}

/// node-postgres returns NUMERIC/DECIMAL columns (price, area_sqm, ...) as
/// JSON strings to avoid float precision loss, so this accepts either a
/// String or a num rather than assuming the API always sends a JSON number.
double? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

VerificationStatus _statusFromString(String? value) {
  switch (value) {
    case 'verified':
      return VerificationStatus.verified;
    case 'rejected':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.pending;
  }
}

/// The backend has no photo/color data — pick a deterministic gradient
/// from the same brand palette the mock listings and category tiles use,
/// so a given property always renders with the same pair of colors.
const _gradientPalette = <List<Color>>[
  [Color(0xFF0F4C4A), Color(0xFFC97B4A)], // teal -> terra
  [Color(0xFFC97B4A), Color(0xFFD4A24C)], // terra -> gold
  [Color(0xFF17706C), Color(0xFFC97B4A)],
  [Color(0xFFD4A24C), Color(0xFFC97B4A)],
  [Color(0xFF4C9A8F), Color(0xFFD4A24C)],
];

List<Color> _gradientFor(String id) {
  final index = id.hashCode.abs() % _gradientPalette.length;
  return _gradientPalette[index];
}
