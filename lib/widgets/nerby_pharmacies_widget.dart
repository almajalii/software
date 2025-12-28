import 'package:flutter/material.dart';
import 'package:meditrack/model/pharmacy.dart';
import 'package:meditrack/services/pharmacy_service.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/screens/main/home/pharmacy_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPharmaciesWidget extends StatefulWidget {
  const NearbyPharmaciesWidget({super.key});

  @override
  State<NearbyPharmaciesWidget> createState() => _NearbyPharmaciesWidgetState();
}

class _NearbyPharmaciesWidgetState extends State<NearbyPharmaciesWidget> {
  final PharmacyService _pharmacyService = PharmacyService();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyPharmacies();
  }

  Future<void> _loadNearbyPharmacies() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location using existing service
      final position = await _pharmacyService.getCurrentLocation();

      if (position == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Enable location to find pharmacies';
          _isLoading = false;
        });
        return;
      }

      // Search for pharmacies using existing service
      final pharmacies = await _pharmacyService.searchNearbyPharmacies(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 5000, // 5km
      );

      if (!mounted) return;
      setState(() {
        _pharmacies = pharmacies.take(3).toList(); // Only take top 3 nearest
        _isLoading = false;
        if (pharmacies.isEmpty) {
          _errorMessage = 'No pharmacies found nearby';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading pharmacies';
        _isLoading = false;
      });
    }
  }

  Future<void> _openInMaps(Pharmacy pharmacy) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}&query_place_id=${pharmacy.placeId}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "See All" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_pharmacy,
                  color: isDarkMode ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nearby Pharmacies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[300] : Colors.black87,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PharmacySearchScreen(),
                  ),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        if (_isLoading)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.grey[500],
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadNearbyPharmacies,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (_pharmacies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No pharmacies found nearby',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
            )
          else
            Column(
              children: _pharmacies.map((pharmacy) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pharmacy.isOpen ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_pharmacy,
                        color: pharmacy.isOpen ? Colors.green[700] : Colors.red[700],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      pharmacy.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (pharmacy.distance != null) ...[
                              Icon(Icons.directions_walk, size: 14, color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${pharmacy.distance!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: pharmacy.isOpen ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pharmacy.isOpen ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: pharmacy.isOpen ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.directions,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () => _openInMaps(pharmacy),
                      tooltip: 'Get Directions',
                    ),
                    onTap: () => _openInMaps(pharmacy),
                  ),
                );
              }).toList(),
            ),
      ],
    );
  }
}