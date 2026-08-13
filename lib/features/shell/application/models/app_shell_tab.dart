enum AppShellTab {
  agenda,
  clients,
  home,
  services,
  more;

  static AppShellTab fromIndex(int index) {
    if (index < 0 || index >= AppShellTab.values.length) {
      return AppShellTab.home;
    }
    return AppShellTab.values[index];
  }
}
