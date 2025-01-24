class TranslationModel {
  final String translation;
  final String code;
  TranslationModel({
    required this.translation,
    required this.code,
  });
  TranslationModel.fromMap(Map<String, dynamic> map)
      : translation = map['translation'],
        code = map['code'];
  Map<String, dynamic> toMap() => {
        'translation': translation,
        'code': code,
      };
  @override
  String toString() {
    return toMap().toString();
  }
}
