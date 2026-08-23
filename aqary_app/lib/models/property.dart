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

  String get formattedPrice {
    final isRent = listingType == 'rent';
    final amount = price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return isRent ? '$currency $amount/mo' : '$currency $amount';
  }
}
