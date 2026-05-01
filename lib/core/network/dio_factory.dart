import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Lazily creates a configured Dio instance per-source so each can have its
/// own base URL, headers, timeouts and cache policy.
class DioFactory {
  DioFactory._();

  static CacheStore? _store;

  static Future<CacheStore> _getStore() async {
    if (_store != null) return _store!;
    if (kIsWeb) {
      // path_provider has no concept of a cache directory on web, and Hive's
      // file-backed store cannot run there. Fall back to an in-memory store
      // (the browser already caches HTTP responses anyway).
      _store = MemCacheStore();
      return _store!;
    }
    final dir = await getApplicationCacheDirectory();
    _store = HiveCacheStore('${dir.path}/http_cache');
    return _store!;
  }

  static Future<Dio> create({
    required String baseUrl,
    Map<String, String>? headers,
    Duration? cacheTtl,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          ...?headers,
        },
        responseType: ResponseType.json,
      ),
    );

    final store = await _getStore();
    dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: store,
          policy: CachePolicy.request,
          maxStale: cacheTtl ?? AppConfig.httpCacheTtl,
          hitCacheOnErrorExcept: const [401, 403],
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: false,
        ),
      ),
    );

    return dio;
  }
}
