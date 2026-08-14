import 'package:flutter/material.dart';

import 'package:lacos_app/features/salon/presentation/pages/salon_page.dart';

var _isOpeningSalon = false;

Future<void> openSalonPage(BuildContext context) async {
  if (_isOpeningSalon) return;

  _isOpeningSalon = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SalonPage()),
    );
  } finally {
    _isOpeningSalon = false;
  }
}

void resetSalonNavigationGuardForTest() {
  _isOpeningSalon = false;
}
