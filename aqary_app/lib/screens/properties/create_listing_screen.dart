import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/properties_service.dart';
import '../../theme/app_theme.dart';

/// Minimal seller listing form — POST /properties. Every new listing
/// starts pending verification (BR-PROP-06), same as a seller sign-up.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _region = TextEditingController();
  final _city = TextEditingController();
  final _locationDetail = TextEditingController();
  final _areaSqm = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();

  String _category = 'residential';
  String _listingType = 'sale';
  String _propertyType = 'villa';
  bool _submitting = false;

  static const _categories = ['residential', 'commercial', 'agriculture', 'industrial'];
  static const _propertyTypes = ['villa', 'apartment', 'land', 'building', 'office', 'shop', 'farm_house'];

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _region.dispose();
    _city.dispose();
    _locationDetail.dispose();
    _areaSqm.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Listing')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            children: [
              const Text(
                'Submitted listings enter the verification queue before they go live in search.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
              ),
              const SizedBox(height: 22),
              _dropdown('CATEGORY', _category, _categories, (v) => setState(() => _category = v!)),
              _dropdown('LISTING TYPE', _listingType, const ['sale', 'rent'], (v) => setState(() => _listingType = v!)),
              _dropdown('PROPERTY TYPE', _propertyType, _propertyTypes, (v) => setState(() => _propertyType = v!)),
              _field('TITLE', 'e.g. 4BR Villa — Al Mouj, Muscat', _title),
              _field('PRICE (OMR)', '185000', _price, keyboardType: TextInputType.number),
              _field('REGION (GOVERNORATE)', 'Muscat', _region),
              _field('CITY (WILAYAT)', 'Muscat', _city),
              _field('NEIGHBOURHOOD (OPTIONAL)', 'Al Mouj', _locationDetail, required: false),
              _field('AREA — SQM (OPTIONAL)', '420', _areaSqm, keyboardType: TextInputType.number, required: false),
              _field('BEDROOMS (OPTIONAL)', '4', _bedrooms, keyboardType: TextInputType.number, required: false),
              _field('BATHROOMS (OPTIONAL)', '5', _bathrooms, keyboardType: TextInputType.number, required: false),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Submit Listing  →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller,
      {TextInputType? keyboardType, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = num.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await PropertiesService.instance.createListing(
        category: _category,
        listingType: _listingType,
        propertyType: _propertyType,
        title: _title.text.trim(),
        price: price,
        region: _region.text.trim(),
        city: _city.text.trim(),
        locationDetail: _locationDetail.text.trim().isEmpty ? null : _locationDetail.text.trim(),
        areaSqm: num.tryParse(_areaSqm.text.trim()),
        bedrooms: int.tryParse(_bedrooms.text.trim()),
        bathrooms: int.tryParse(_bathrooms.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing submitted for verification.'), backgroundColor: AppColors.tealDark),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection.'), backgroundColor: AppColors.danger),
      );
    }
  }
}
