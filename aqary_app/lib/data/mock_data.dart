import 'package:flutter/material.dart';
import '../models/category_item.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

/// Static stand-in for the backend described in the Properties Module
/// Architecture doc. Every list here matches a row (or group of rows) in
/// the `properties` taxonomy table — swap this file for real API calls
/// (GET /properties/categories, GET /properties?...) when the backend
/// is ready; no screen code should need to change.
class MockData {
  MockData._();

  // ---------------- Properties: top-level categories ----------------
  static const topLevelCategories = <CategoryItem>[
    CategoryItem(
      id: 'residential',
      label: 'Residential',
      icon: Icons.home_rounded,
      gradient: [Color(0xFFDE9865), Color(0xFFB5673A)],
    ),
    CategoryItem(
      id: 'commercial',
      label: 'Commercial',
      icon: Icons.apartment_rounded,
      gradient: [Color(0xFF17706C), AppColors.tealDark],
    ),
    CategoryItem(
      id: 'agriculture',
      label: 'Agriculture',
      icon: Icons.agriculture_rounded,
      gradient: [Color(0xFF3E8C82), AppColors.teal],
    ),
    CategoryItem(
      id: 'industrial',
      label: 'Industrial',
      icon: Icons.factory_rounded,
      gradient: [Color(0xFF8A8A87), Color(0xFF4A4A47)],
    ),
  ];

  // ---------------- Residential: Buy / Rent / Sell ----------------
  static const residentialOptions = <CategoryItem>[
    CategoryItem(
      id: 'buy',
      label: 'Buy',
      description: 'Villa, apartment, or land — freehold & leasehold',
      icon: Icons.volunteer_activism_rounded,
      gradient: [Color(0xFF17706C), AppColors.tealDark],
    ),
    CategoryItem(
      id: 'rent',
      label: 'Rent',
      description: 'Monthly & yearly leases, move-in ready',
      icon: Icons.vpn_key_rounded,
      gradient: [Color(0xFFDE9865), Color(0xFFB5673A)],
    ),
    CategoryItem(
      id: 'sell',
      label: 'Sell',
      description: 'List your own property for AQARY to verify',
      icon: Icons.sell_rounded,
      gradient: [AppColors.gold, Color(0xFF9C6A2A)],
    ),
  ];

  // ---------------- Buy: Villa / Apartment / Land ----------------
  static const buyPropertyTypes = <CategoryItem>[
    CategoryItem(
      id: 'apartment',
      label: 'Apartment',
      icon: Icons.layers_rounded,
      gradient: [Color(0xFF237E78), AppColors.tealDark],
    ),
    CategoryItem(
      id: 'villa',
      label: 'Villa',
      icon: Icons.villa_rounded,
      gradient: [Color(0xFFE0A26B), Color(0xFFA85A31)],
    ),
    CategoryItem(
      id: 'land',
      label: 'Land',
      icon: Icons.terrain_rounded,
      gradient: [Color(0xFF4C9A8F), AppColors.teal],
    ),
  ];

  // ---------------- Rent: Apartment / Villa (no Land) ----------------
  static final rentPropertyTypes = <CategoryItem>[
    buyPropertyTypes[0], // Apartment
    buyPropertyTypes[1], // Villa
  ];

  // ---------------- Commercial: Building / Land / Office / Shop -------
  static const commercialPropertyTypes = <CategoryItem>[
    CategoryItem(
      id: 'building',
      label: 'Building',
      icon: Icons.apartment_rounded,
      gradient: [Color(0xFF17706C), AppColors.tealDark],
    ),
    CategoryItem(
      id: 'land',
      label: 'Land',
      icon: Icons.terrain_rounded,
      gradient: [Color(0xFF4C9A8F), AppColors.teal],
    ),
    CategoryItem(
      id: 'office',
      label: 'Office',
      icon: Icons.work_rounded,
      gradient: [Color(0xFFDE9865), Color(0xFFB5673A)],
    ),
    CategoryItem(
      id: 'shop',
      label: 'Shops',
      icon: Icons.storefront_rounded,
      gradient: [Color(0xFFE0A26B), Color(0xFFA85A31)],
    ),
  ];

  // ---------------- Agriculture: Land / Farm House ----------------
  static const agriculturePropertyTypes = <CategoryItem>[
    CategoryItem(
      id: 'land',
      label: 'Land',
      description: 'Cultivable plots with water rights',
      icon: Icons.terrain_rounded,
      gradient: [Color(0xFF4C9A8F), AppColors.teal],
    ),
    CategoryItem(
      id: 'farmhouse',
      label: 'Farm House',
      description: 'Working farms with residence',
      icon: Icons.cottage_rounded,
      gradient: [Color(0xFFDE9865), Color(0xFFB5673A)],
    ),
  ];

  /// Sample listings — filtered client-side here to simulate what
  /// GET /properties?category=...&listing_type=...&property_type=...
  /// will return once the backend exists.
  static const List<Property> listings = [
    Property(
      id: 'p1',
      category: 'residential',
      listingType: 'sale',
      propertyType: 'villa',
      title: '4BR Villa — Madinat Al Ilam, Muscat',
      price: 185000,
      wilayat: 'Muscat',
      city: 'Madinat Al Ilam',
      areaSqm: 420,
      bedrooms: 4,
      bathrooms: 5,
      status: VerificationStatus.verified,
      imageGradient: [AppColors.teal, AppColors.terra],
    ),
    Property(
      id: 'p2',
      category: 'residential',
      listingType: 'sale',
      propertyType: 'villa',
      title: '5BR Villa — Al Mouj, Muscat',
      price: 235000,
      wilayat: 'Muscat',
      city: 'Al Mouj',
      areaSqm: 510,
      bedrooms: 5,
      bathrooms: 6,
      status: VerificationStatus.verified,
      imageGradient: [AppColors.terra, AppColors.gold],
    ),
    Property(
      id: 'p3',
      category: 'residential',
      listingType: 'sale',
      propertyType: 'apartment',
      title: '2BR Apartment — Al Khuwair, Muscat',
      price: 62000,
      wilayat: 'Muscat',
      city: 'Al Khuwair',
      areaSqm: 140,
      bedrooms: 2,
      bathrooms: 2,
      status: VerificationStatus.verified,
      imageGradient: [Color(0xFF17706C), AppColors.terra],
    ),
    Property(
      id: 'p4',
      category: 'residential',
      listingType: 'rent',
      propertyType: 'apartment',
      title: '1BR Apartment — Qurum, Muscat',
      price: 320,
      wilayat: 'Muscat',
      city: 'Qurum',
      areaSqm: 85,
      bedrooms: 1,
      bathrooms: 1,
      status: VerificationStatus.verified,
      imageGradient: [AppColors.gold, AppColors.terra],
    ),
    Property(
      id: 'p5',
      category: 'residential',
      listingType: 'sale',
      propertyType: 'land',
      title: 'Residential Plot — Al Amerat, Muscat',
      price: 95000,
      wilayat: 'Muscat',
      city: 'Al Amerat',
      areaSqm: 600,
      status: VerificationStatus.verified,
      imageGradient: [Color(0xFF4C9A8F), AppColors.gold],
    ),
  ];

  static List<Property> filterListings({
    required String category,
    String? listingType,
    required String propertyType,
  }) {
    return listings
        .where((p) =>
            p.category == category &&
            p.propertyType == propertyType &&
            (listingType == null || p.listingType == listingType))
        .toList();
  }
}
