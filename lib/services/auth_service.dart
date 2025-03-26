import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Cadastro de usuário
  Future<String?> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return null; // Cadastro bem-sucedido
      }
      return "Erro desconhecido ao cadastrar";
    } catch (e) {
      return e.toString();
    }
  }

  // Login do usuário
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return null; // Login bem-sucedido
      }
      return "Erro desconhecido no login";
    } catch (e) {
      return e.toString();
    }
  }

  // Logout do usuário
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
