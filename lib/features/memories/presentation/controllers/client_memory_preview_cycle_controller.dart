/// Controla o índice cíclico do preview de memórias na ficha da cliente.
///
/// Sem timer embutido — o widget agenda o intervalo e chama [advance].
class ClientMemoryPreviewCycleController {
  ClientMemoryPreviewCycleController({
    required List<String> itemIds,
    int initialIndex = 0,
  }) : _itemIds = List<String>.unmodifiable(itemIds) {
    _currentIndex = _normalizeIndex(initialIndex);
  }

  List<String> _itemIds;
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  int get itemCount => _itemIds.length;
  bool get isEmpty => _itemIds.isEmpty;
  bool get hasMultipleItems => _itemIds.length > 1;
  bool get shouldAutoRotate => hasMultipleItems;

  String? get currentItemId {
    if (_itemIds.isEmpty) return null;
    return _itemIds[_currentIndex];
  }

  /// Avança para o próximo item (cíclico).
  /// Retorna `true` se o índice mudou.
  bool advance() {
    if (!hasMultipleItems) return false;
    _currentIndex = (_currentIndex + 1) % _itemIds.length;
    return true;
  }

  /// Retrocede para o item anterior (cíclico).
  bool goToPrevious() {
    if (!hasMultipleItems) return false;
    _currentIndex = (_currentIndex - 1 + _itemIds.length) % _itemIds.length;
    return true;
  }

  /// Vai para um índice específico, se válido.
  bool goTo(int index) {
    if (!hasMultipleItems) return false;
    if (index < 0 || index >= _itemIds.length) return false;
    if (index == _currentIndex) return false;
    _currentIndex = index;
    return true;
  }

  /// Atualiza a lista preservando o índice quando possível.
  ///
  /// - Se o item atual ainda existe, mantém a posição dele.
  /// - Se foi removido, clampa para um índice válido (ou 0).
  /// - Se a lista ficou vazia, índice = 0.
  void updateItems(List<String> itemIds) {
    final previousId = currentItemId;
    _itemIds = List<String>.unmodifiable(itemIds);

    if (_itemIds.isEmpty) {
      _currentIndex = 0;
      return;
    }

    if (previousId != null) {
      final preserved = _itemIds.indexOf(previousId);
      if (preserved >= 0) {
        _currentIndex = preserved;
        return;
      }
    }

    _currentIndex = _normalizeIndex(_currentIndex);
  }

  int _normalizeIndex(int index) {
    if (_itemIds.isEmpty) return 0;
    if (index < 0) return 0;
    if (index >= _itemIds.length) return _itemIds.length - 1;
    return index;
  }
}
