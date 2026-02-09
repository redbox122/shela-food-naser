import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/cache/cached_data_loader.dart';

/// Debug screen to show cache statistics and controls
class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({super.key});

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  Map<String, dynamic>? cacheInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => isLoading = true);
    try {
      final info = await CachedDataLoader.getCacheStats();
      setState(() {
        cacheInfo = info;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to load cache info: $e');
    }
  }

  Future<void> _clearCache() async {
    setState(() => isLoading = true);
    try {
      await CachedDataLoader.clearCacheAndRefresh(context);
      await _loadCacheInfo();
      Get.snackbar('Success', 'Cache cleared and refreshed');
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to clear cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheInfo,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cacheInfo == null
              ? const Center(child: Text('No cache info available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cache Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Has Cache: ${cacheInfo!['hasCache']}'),
                              Text(
                                  'Cache Age: ${cacheInfo!['cacheAge']} hours'),
                              Text('Is Valid: ${cacheInfo!['isValid']}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Version Info',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Cached App Version: ${cacheInfo!['cachedAppVersion']}'),
                              Text(
                                  'Current App Version: ${cacheInfo!['currentAppVersion']}'),
                              Text(
                                  'Cached Bootstrap: ${cacheInfo!['cachedBootstrapVersion']}'),
                              Text(
                                  'Current Bootstrap: ${cacheInfo!['currentBootstrapVersion']}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _clearCache,
                                child: const Text('Clear Cache & Refresh'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadCacheInfo,
                                child: const Text('Refresh Info'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
