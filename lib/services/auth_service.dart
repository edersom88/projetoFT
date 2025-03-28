import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Cadastro de usuário
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
    required String document,
    required String phone,
    required String street,
    required String number,
    required String postalcode,
    required String neighborhood,
    required String city,
    required String state,
    required String country,
    required String complement,
    required bool isGoalkeeper,
  }) async {
    try {
      final response = await supabase.auth.signUp(email: email, password: password);
      
      if (response.session == null) {
        return "Verifique seu e-mail para confirmar o cadastro.";
      }

      // Converter número de forma segura
      int? parsedNumber = int.tryParse(number);
      if (parsedNumber == null) {
        return "Número do endereço inválido.";
      }

      // Inserir os dados na tabela 'users'
      await supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'username': username,
        'document': document,
        'phone': phone,
        'street': street,
        'number': parsedNumber,
        'postalcode': postalcode,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'country': country,
        'complement': complement,
        'is_goalkeeper': isGoalkeeper,
        'created_at': DateTime.now().toIso8601String(),
      });

      return null; // Sucesso
    } catch (error) {
      print(error.toString());
      return "Erro ao criar conta: ${error.toString()}";
    }
  }

  // Login do usuário
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        return null; // Login bem-sucedido
      }
      return "E-mail ou senha incorretos.";
    } catch (e) {
      return "Erro ao fazer login: ${e.toString()}";
    }
  }

  // Logout do usuário
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
