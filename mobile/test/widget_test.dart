import 'package:flutter_test/flutter_test.dart';
import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/features/history/viewed_food_history_store.dart';
import 'package:nutrifit/main.dart';

void main() {
  testWidgets('bottom nav renders five tabs and starts on home', (tester) async {
    final api = NutriFitApi(baseUrl: Uri.parse('http://localhost:8000'));
    await tester.pumpWidget(
      NutriFitApp(
        api: api,
        history: InMemoryViewedFoodHistoryStore(),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('NutriFit Dashboard'), findsOneWidget);
    expect(find.text('Health tracking'), findsOneWidget);
    api.close();
  });
}
