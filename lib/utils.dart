import 'dart:io';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/config_screen.dart';

const Color kFundoCard = Color(0xFF1E1E1E);

void aviso(BuildContext context, String texto) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

String mensagemErro(Object e) {
  if (e is FormatException) {
    return 'A IA devolveu um formato inesperado. Tente de novo com uma imagem mais nítida.';
  }
  final t = e.toString();
  final baixo = t.toLowerCase();
  if (e is SocketException ||
      baixo.contains('socketexception') ||
      baixo.contains('failed host lookup') ||
      baixo.contains('clientexception')) {
    return 'Sem conexão com a internet.';
  }
  if (baixo.contains('api key') ||
      baixo.contains('api_key') ||
      baixo.contains('permission_denied') ||
      baixo.contains('403')) {
    return 'Chave do Gemini inválida ou sem permissão. Confira em Configurações.';
  }
  if (baixo.contains('quota') ||
      baixo.contains('429') ||
      baixo.contains('resource_exhausted')) {
    return 'Limite da API atingido. Tente de novo daqui a pouco.';
  }
  if (baixo.contains('not found') || baixo.contains('404')) {
    return 'Modelo não encontrado. Troque o nome do modelo em Configurações.';
  }
  return 'Erro: $t';
}

Future<bool> garantirChave(BuildContext context) async {
  if (appState.apiKey.isNotEmpty) return true;
  final ir = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: kFundoCard,
      title: const Text('Chave do Gemini necessária'),
      content: const Text(
          'Para usar a IA, cadastre sua chave gratuita do Gemini nas configurações.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Abrir configurações'),
        ),
      ],
    ),
  );
  if (ir == true && context.mounted) {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ConfigScreen()));
  }
  return appState.apiKey.isNotEmpty;
}

Future<bool> confirmar(BuildContext context, String titulo, String texto) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: kFundoCard,
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  return r == true;
}

Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  String inicial = '',
  String? dica,
  int linhas = 1,
}) async {
  final controller = TextEditingController(text: inicial);
  final r = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: kFundoCard,
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: linhas,
        decoration: InputDecoration(hintText: dica),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return r;
}
