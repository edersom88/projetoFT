import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart' show PostgrestException;
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Address controllers
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  
  bool _isGoalkeeper = false;
  double _goalkeeperFee = 50.0;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<String> _getLocationFromAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = data[0]['lat'];
          final lon = data[0]['lon'];
          return 'POINT($lon $lat)';
        }
      }
      return 'POINT(0 0)';
    } catch (e) {
      return 'POINT(0 0)';
    }
  }

  Future<void> _handleSignUp() async {
    if (!_validatePersonalData() || !_validateAddress()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Registrar no Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Falha ao registrar usuário');
      }

      // 2. Preparar dados do endereço concatenado
      final address = [
        _streetController.text.trim(),
        _numberController.text.trim(),
        if (_complementController.text.isNotEmpty) _complementController.text.trim(),
        _neighborhoodController.text.trim(),
        _cityController.text.trim(),
        _stateController.text.trim(),
        _countryController.text.trim(),
        _postalCodeController.text.trim(),
      ].join(', ');

      // 3. Obter localização geográfica
      final location = await _getLocationFromAddress(address);

      // 4. Preparar dados do usuário
      final userData = {
        'id': authResponse.user!.id,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'document': _documentController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'number': int.tryParse(_numberController.text.trim()) ?? 0,
        'postalcode': _postalCodeController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'complement': _complementController.text.trim().isEmpty 
            ? null 
            : _complementController.text.trim(),
        'is_goalkeeper': _isGoalkeeper,
        'goalkeeper_fee': _isGoalkeeper ? _goalkeeperFee : 0.0,
        'address': address,
        'location': location,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 5. Inserir na tabela users
      final response = await _supabase
          .from('users')
          .insert(userData);

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      // Sucesso
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro realizado com sucesso!")),
      );
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPersonalDataStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "E-mail*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Senha*"),
          validator: (value) => value!.length < 6 
              ? 'Mínimo de 6 caracteres' 
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Confirmar Senha*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Nome Completo*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: "Username*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _documentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "CPF/CNPJ*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Telefone*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _isGoalkeeper,
              onChanged: (value) {
                setState(() => _isGoalkeeper = value ?? false);
              },
            ),
            const Text("Sou goleiro"),
          ],
        ),
        if (_isGoalkeeper) ...[
          const SizedBox(height: 12),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Valor da Taxa (R\$)*",
              prefixText: "R\$ ",
            ),
            onChanged: (value) {
              _goalkeeperFee = double.tryParse(value) ?? 50.0;
            },
            validator: (value) => _isGoalkeeper && (value == null || value.isEmpty)
                ? 'Informe o valor da taxa'
                : null,
            initialValue: '50.00',
          ),
        ],
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      children: [
        TextFormField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "CEP*",
            hintText: "00000-000",
            suffixIcon: Icon(Icons.search),
          ),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          onChanged: (value) {
            if (value.length == 8) {
              _fetchAddressByCEP();
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: "Rua*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Número*"),
          validator: (value) {
            if (value!.isEmpty) return 'Campo obrigatório';
            if (int.tryParse(value) == null) return 'Digite um número válido';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _complementController,
          decoration: const InputDecoration(labelText: "Complemento"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _neighborhoodController,
          decoration: const InputDecoration(labelText: "Bairro*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: "Cidade*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _stateController,
          decoration: const InputDecoration(labelText: "Estado*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(labelText: "País*"),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  Future<void> _fetchAddressByCEP() async {
    final cep = _postalCodeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cep.length == 8) {
      setState(() => _isLoading = true);
      
      try {
        final response = await http.get(
          Uri.parse('https://viacep.com.br/ws/$cep/json/')
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['erro'] != true) {
            setState(() {
              _streetController.text = data['logradouro'] ?? '';
              _neighborhoodController.text = data['bairro'] ?? '';
              _cityController.text = data['localidade'] ?? '';
              _stateController.text = data['uf'] ?? '';
              // Foca automaticamente no campo número
              FocusScope.of(context).nextFocus();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("CEP não encontrado!")),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao buscar CEP: ${e.toString()}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stepper(
          currentStep: _currentStep,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (_currentStep != 0)
                    OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Voltar'),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_currentStep == 0) {
                          if (_validatePersonalData()) {
                            setState(() => _currentStep += 1);
                          }
                        } else {
                          await _handleSignUp();
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(_currentStep == 1 ? 'Cadastrar' : 'Próximo'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Dados Pessoais'),
              content: _buildPersonalDataStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Endereço'),
              content: _buildAddressStep(),
              isActive: _currentStep >= 1,
            ),
          ],
        ),
      ),
    );
  }

  bool _validatePersonalData() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-mail inválido!")),
      );
      return false;
    }

    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha deve ter pelo menos 6 caracteres!")),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem!")),
      );
      return false;
    }

    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _documentController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return false;
    }

    if (_isGoalkeeper && _goalkeeperFee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe um valor válido para a taxa!")),
      );
      return false;
    }

    return true;
  }

  bool _validateAddress() {
    if (_postalCodeController.text.isEmpty ||
        _streetController.text.isEmpty ||
        _numberController.text.isEmpty ||
        _neighborhoodController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _countryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos de endereço!")),
      );
      return false;
    }
    return true;
  }
}