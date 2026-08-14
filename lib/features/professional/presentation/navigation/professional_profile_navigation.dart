import 'package:flutter/material.dart';

import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';

var _isOpeningProfessionalProfile = false;

Future<void> openProfessionalProfile(BuildContext context) async {
  if (_isOpeningProfessionalProfile) return;

  _isOpeningProfessionalProfile = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfessionalProfilePage(),
      ),
    );
  } finally {
    _isOpeningProfessionalProfile = false;
  }
}

void resetProfessionalProfileNavigationGuardForTest() {
  _isOpeningProfessionalProfile = false;
}
