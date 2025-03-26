import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'package:projetoft/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gqelclbvawurwpokextd.supabase.co', // Substitua pelo seu URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxZWxjbGJ2YXd1cndwb2tleHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5OTYyNDMsImV4cCI6MjA1ODU3MjI0M30.ZHn18TEIFHbO_6r6yqfdL2VRVUQVvF7RxB50LWE2QO8', // Substitua pela sua chave anônima
  );

  final session = Supabase.instance.client.auth.currentSession;

  runApp(MyApp(initialScreen: session != null ? HomeScreen() : LoginScreen()));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}