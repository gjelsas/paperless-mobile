extension ToggleableItemListExtension<T> on List<T> {
  List<T> toggle(T element) {
    if (contains(element)) {
      return where((e) => e != element).toList();
    } else {
      return [...this, element];
    }
  }
}
