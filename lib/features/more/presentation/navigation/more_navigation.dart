import 'package:flutter/material.dart';

import 'package:lacos_app/features/monetization/presentation/pages/premium_page.dart';
import 'package:lacos_app/features/more/presentation/pages/about_page.dart';
import 'package:lacos_app/features/more/presentation/pages/help_support_page.dart';

var _isOpeningHelp = false;
var _isOpeningAbout = false;
var _isOpeningPremium = false;

Future<void> openHelpSupport(BuildContext context) async {
  if (_isOpeningHelp) return;

  _isOpeningHelp = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const HelpSupportPage()),
    );
  } finally {
    _isOpeningHelp = false;
  }
}

Future<void> openAboutLacos(BuildContext context) async {
  if (_isOpeningAbout) return;

  _isOpeningAbout = true;
  try {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const AboutPage()));
  } finally {
    _isOpeningAbout = false;
  }
}

Future<void> openPremiumPage(BuildContext context) async {
  if (_isOpeningPremium) return;

  _isOpeningPremium = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const PremiumPage()),
    );
  } finally {
    _isOpeningPremium = false;
  }
}

void resetMoreNavigationGuardsForTest() {
  _isOpeningHelp = false;
  _isOpeningAbout = false;
  _isOpeningPremium = false;
}
