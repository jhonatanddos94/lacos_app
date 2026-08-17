import 'package:flutter/material.dart';

import 'package:lacos_app/features/working_hours/presentation/pages/professional_working_hours_page.dart';

var _isOpeningWorkingHours = false;

Future<void> openProfessionalWorkingHoursPage(BuildContext context) async {
  if (_isOpeningWorkingHours) return;

  _isOpeningWorkingHours = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfessionalWorkingHoursPage(),
      ),
    );
  } finally {
    _isOpeningWorkingHours = false;
  }
}

void resetWorkingHoursNavigationGuardForTest() {
  _isOpeningWorkingHours = false;
}
