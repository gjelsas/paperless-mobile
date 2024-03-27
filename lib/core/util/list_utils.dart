extension ToggleableItemListExtension<T> on Iterable<T> {
  Iterable<T> toggle(T element) {
    if (contains(element)) {
      return where((e) => e != element).toList();
    } else {
      return [...this, element];
    }
  }
}
