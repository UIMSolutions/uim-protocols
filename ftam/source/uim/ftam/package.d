/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.ftam;

import vibe.d;

mixin(ShowModule!());

public {
  import uim.core;
  import uim.oop;
}

public {
  import uim.ftam.interfaces;
  import uim.ftam.models;
  import uim.ftam.helpers;
}

public {
  import uim.ftam.service;
}
