import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createAuthHttpClientAdapter() {
  return BrowserHttpClientAdapter()..withCredentials = true;
}
