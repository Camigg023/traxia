import 'dart:js_interop';

@JS('window.localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('window.localStorage.setItem')
external void _setItem(JSString key, JSString value);

String? getSavedValue(String key) {
  try {
    final val = _getItem(key.toJS);
    return val?.toDart;
  } catch (_) {
    return null;
  }
}

void saveValue(String key, String value) {
  try {
    _setItem(key.toJS, value.toJS);
  } catch (_) {}
}