import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const String kModeloPadrao = 'gemini-2.5-flash';

class AppState extends ChangeNotifier {
  List<Treino> treinos = [];
  List<Sessao> historico = [];
  String apiKey = '';
  String modelo = kModeloPadrao;

  Future<void> carregar() async {
    final p = await SharedPreferences.getInstance();
    apiKey = p.getString('geminiKey') ?? '';
    modelo = p.getString('modelo') ?? kModeloPadrao;
    try {
      final t = p.getString('treinos_v2');
      if (t != null) {
        treinos = (jsonDecode(t) as List)
            .map((e) => Treino.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final h = p.getString('historico_v2');
      if (h != null) {
        historico = (jsonDecode(h) as List)
            .map((e) => Sessao.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // dados corrompidos: começa vazio
    }
    notifyListeners();
  }

  Future<void> salvar() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'treinos_v2', jsonEncode(treinos.map((t) => t.toJson()).toList()));
    await p.setString(
        'historico_v2', jsonEncode(historico.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  Future<void> salvarConfig(String chave, String novoModelo) async {
    final p = await SharedPreferences.getInstance();
    apiKey = chave;
    modelo = novoModelo.isEmpty ? kModeloPadrao : novoModelo;
    await p.setString('geminiKey', apiKey);
    await p.setString('modelo', modelo);
    notifyListeners();
  }

  /// Última carga registrada no histórico para um exercício (pelo nome).
  double? ultimaCarga(String nome) {
    final alvo = nome.toLowerCase().trim();
    for (var i = historico.length - 1; i >= 0; i--) {
      for (final item in historico[i].itens) {
        if (item.nome.toLowerCase().trim() == alvo) return item.carga;
      }
    }
    return null;
  }

  String exportar() => jsonEncode({
        'versao': 2,
        'treinos': treinos.map((t) => t.toJson()).toList(),
        'historico': historico.map((s) => s.toJson()).toList(),
      });

  Future<void> importar(String texto) async {
    final m = jsonDecode(texto) as Map;
    final novosTreinos = (m['treinos'] as List)
        .map((e) => Treino.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final novoHistorico = ((m['historico'] as List?) ?? [])
        .map((e) => Sessao.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    treinos = novosTreinos;
    historico = novoHistorico;
    await salvar();
  }
}

final AppState appState = AppState();
