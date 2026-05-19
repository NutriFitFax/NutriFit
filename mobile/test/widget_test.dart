import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/main.dart';

void main() {
  testWidgets('bottom nav renders all three tabs', (tester) async {
    final api = NutriFitApi(baseUrl: Uri.parse('http://localhost:8000'));
    await tester.pumpWidget(NutriFitApp(api: api));
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
    api.close();
  });
}
