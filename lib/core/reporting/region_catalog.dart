import 'dart:convert';

import 'package:flutter/services.dart';

/// A local government area, identified by its OCHA P-code (e.g. NG019009).
class Lga {
  const Lga({required this.pcode, required this.name});
  final String pcode;
  final String name;
}

/// A state (or the FCT) and its LGAs.
class NgState {
  const NgState({required this.pcode, required this.name, required this.lgas});
  final String pcode;
  final String name;
  final List<Lga> lgas;
}

/// Nigeria's 36 states, the FCT and their 774 LGAs, bundled so a farmer can
/// pick where they farm with no signal. Built by tool/build_regions.py from
/// OCHA's COD-AB boundaries — the same codes the surveillance server uses.
class RegionCatalog {
  RegionCatalog._(this.states);

  final List<NgState> states;

  static RegionCatalog? _instance;

  static Future<RegionCatalog> load() async {
    if (_instance != null) return _instance!;
    final raw = jsonDecode(
            await rootBundle.loadString('assets/regions/nigeria_lgas.json'))
        as Map<String, dynamic>;
    return _instance = RegionCatalog._([
      for (final s in raw['states'] as List)
        NgState(
          pcode: s['pcode'] as String,
          name: s['name'] as String,
          lgas: [
            for (final l in s['lgas'] as List)
              Lga(pcode: l['pcode'] as String, name: l['name'] as String),
          ],
        ),
    ]);
  }

  NgState? state(String? pcode) {
    for (final s in states) {
      if (s.pcode == pcode) return s;
    }
    return null;
  }
}
