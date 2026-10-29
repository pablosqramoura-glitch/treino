import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'app_state.dart';
import 'models.dart';

class IaService {
  static String _limpar(String t) =>
      t.replaceAll('```json', '').replaceAll('```', '').trim();

  static GenerativeModel _modelo() => GenerativeModel(
        model: appState.modelo,
        apiKey: appState.apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

  static const String _promptPlanilha = '''
Analise o arquivo de treino fornecido (foto ou PDF de uma planilha de academia).
Responda SOMENTE com um JSON (lista), sem texto extra, neste formato:
[{
  "dia": "Treino A",
  "gruposMusculares": ["Peito", "Tríceps"],
  "exercicios": [
    {"nome": "Supino Reto", "series": 4, "repeticoes": "10-12", "descanso": 90, "carga": 0}
  ]
}]
Regras: "descanso" em segundos (use 60 se não constar), "carga" em kg (use 0 se não constar),
"series" é um número inteiro e "repeticoes" é texto. Escreva tudo em português.
Se houver vários dias de treino (A, B, C...), devolva um item da lista para cada um.
''';

  static Future<List<Treino>> lerPlanilha(Uint8List bytes, String mime) async {
    final resp = await _modelo().generateContent([
      Content.multi([TextPart(_promptPlanilha), DataPart(mime, bytes)]),
    ]);
    final decoded = jsonDecode(_limpar(resp.text ?? ''));
    List<dynamic> lista;
    if (decoded is List) {
      lista = decoded;
    } else if (decoded is Map && decoded['treinos'] is List) {
      lista = decoded['treinos'] as List;
    } else {
      lista = [decoded];
    }
    return lista
        .map<Treino>(
            (e) => Treino.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<Sugestao>> sugerir(Treino t) async {
    final recentes = appState.historico.where((s) => s.treinoId == t.id).toList();
    final ultimos =
        recentes.length > 5 ? recentes.sublist(recentes.length - 5) : recentes;

    final prompt = '''
Você é um personal trainer experiente. Treino atual (JSON):
${jsonEncode(t.toJson())}

Últimas sessões registradas deste treino (JSON, pode estar vazio):
${jsonEncode(ultimos.map((s) => s.toJson()).toList())}

Sugira a progressão para a próxima sessão. Aumente a carga com cautela, em pequenos incrementos,
quando o histórico indicar que o treino está sendo completado; mantenha se não houver histórico.
Responda SOMENTE com JSON (lista), um item por exercício que deve mudar:
[{"nome": "nome EXATO do exercício", "series": 4, "repeticoes": "8-10", "carga": 32.5, "motivo": "frase curta"}]
Escreva em português.
''';

    final resp = await _modelo().generateContent([Content.text(prompt)]);
    final decoded = jsonDecode(_limpar(resp.text ?? ''));
    final lista = decoded is List ? decoded : [decoded];
    return lista
        .map<Sugestao>(
            (e) => Sugestao.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
