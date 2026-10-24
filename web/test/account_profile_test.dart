import 'package:flutter_test/flutter_test.dart';
import 'package:traxia_web/screens/create_account_screen.dart';

void main() {
  test('presenta los tres perfiles aprobados para la plataforma web', () {
    expect(AccountProfile.values, hasLength(3));
    expect(
      AccountProfile.values.map((profile) => profile.label),
      containsAll([
        'Empresa que solicita transporte',
        'Conductor',
        'Empresa legalizadora',
      ]),
    );
  });
}
