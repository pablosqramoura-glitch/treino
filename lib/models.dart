String novoId() => DateTime.now().microsecondsSinceEpoch.toString();

int paraInt(dynamic v, int padrao) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? padrao;
  return padrao;
}

double paraDouble(dynamic v, double padrao) {
  if (v is num) return v.toDouble();
  if (v is String) {
    return double.tryParse(v.trim().replaceAll(',', '.')) ?? padrao;
  }
  return padrao;
}

String fmtCarga(double c) => c % 1 == 0 ? '${c.toInt()}' : c.toStringAsFixed(1);

String fmtData(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)}/${l.year} ${dois(l.hour)}:${dois(l.minute)}';
}

class Exercicio {
  String nome;
  int series;
  String repeticoes;
  int descanso;
  double carga;

  Exercicio({
    required this.nome,
    this.series = 3,
    this.repeticoes = '10-12',
    this.descanso = 60,
    this.carga = 0,
  });

  factory Exercicio.fromJson(Map<String, dynamic> j) => Exercicio(
        nome: '${j['nome'] ?? 'Exercício'}',
        series: paraInt(j['series'], 3).clamp(1, 20).toInt(),
        repeticoes: '${j['repeticoes'] ?? '10'}',
        descanso: paraInt(j['descanso'], 60).clamp(0, 600).toInt(),
        carga: paraDouble(j['carga'], 0),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'series': series,
        'repeticoes': repeticoes,
        'descanso': descanso,
        'carga': carga,
      };
}

class Treino {
  String id;
  String dia;
  List<String> grupos;
  List<Exercicio> exercicios;
  String? ultimoTreino;

  Treino({
    required this.id,
    required this.dia,
    required this.grupos,
    required this.exercicios,
    this.ultimoTreino,
  });

  factory Treino.fromJson(Map<String, dynamic> j) {
    final grupos = <String>[];
    final g = j['gruposMusculares'];
    if (g is List) {
      for (final item in g) {
        grupos.add('$item');
      }
    }
    final exercicios = <Exercicio>[];
    final e = j['exercicios'];
    if (e is List) {
      for (final item in e) {
        exercicios.add(Exercicio.fromJson(Map<String, dynamic>.from(item as Map)));
      }
    }
    return Treino(
      id: j['id']?.toString() ?? novoId(),
      dia: '${j['dia'] ?? 'Treino'}',
      grupos: grupos,
      exercicios: exercicios,
      ultimoTreino: j['ultimoTreino']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dia': dia,
        'gruposMusculares': grupos,
        'exercicios': exercicios.map((e) => e.toJson()).toList(),
        'ultimoTreino': ultimoTreino,
      };
}

class SessaoItem {
  final String nome;
  final double carga;
  final int series;

  SessaoItem({required this.nome, required this.carga, required this.series});

  factory SessaoItem.fromJson(Map<String, dynamic> j) => SessaoItem(
        nome: '${j['nome'] ?? ''}',
        carga: paraDouble(j['carga'], 0),
        series: paraInt(j['series'], 0),
      );

  Map<String, dynamic> toJson() => {'nome': nome, 'carga': carga, 'series': series};
}

class Sessao {
  final String id;
  final String data;
  final String treinoId;
  final String treinoNome;
  final List<SessaoItem> itens;

  Sessao({
    required this.id,
    required this.data,
    required this.treinoId,
    required this.treinoNome,
    required this.itens,
  });

  factory Sessao.fromJson(Map<String, dynamic> j) {
    final itens = <SessaoItem>[];
    final l = j['itens'];
    if (l is List) {
      for (final item in l) {
        itens.add(SessaoItem.fromJson(Map<String, dynamic>.from(item as Map)));
      }
    }
    return Sessao(
      id: j['id']?.toString() ?? novoId(),
      data: '${j['data'] ?? ''}',
      treinoId: '${j['treinoId'] ?? ''}',
      treinoNome: '${j['treinoNome'] ?? ''}',
      itens: itens,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
        'treinoId': treinoId,
        'treinoNome': treinoNome,
        'itens': itens.map((i) => i.toJson()).toList(),
      };
}

class Sugestao {
  final String nome;
  final int? series;
  final String? repeticoes;
  final double? carga;
  final String motivo;

  Sugestao({
    required this.nome,
    this.series,
    this.repeticoes,
    this.carga,
    this.motivo = '',
  });

  factory Sugestao.fromJson(Map<String, dynamic> j) => Sugestao(
        nome: '${j['nome'] ?? ''}',
        series: j['series'] == null ? null : paraInt(j['series'], 3),
        repeticoes: j['repeticoes']?.toString(),
        carga: j['carga'] == null ? null : paraDouble(j['carga'], 0),
        motivo: '${j['motivo'] ?? ''}',
      );
}
