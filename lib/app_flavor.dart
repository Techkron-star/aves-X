enum AppFlavor { play, izzy, libre }

extension ExtraAppFlavor on AppFlavor {
  bool get hasMapStyleDefault {
    switch (this) {
      case .play:
        return true;
      case .izzy:
      case .libre:
        return false;
    }
  }
}
