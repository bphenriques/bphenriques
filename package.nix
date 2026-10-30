{ lib, runCommandLocal, writeText, mustache-go, fleet }:
let
  services = lib.attrValues fleet.services;
  listedServices = lib.filter (s: s.listed) services;
  moreCount = builtins.length services - builtins.length listedServices;

  categoryOrder = [ "identity" "media" "media automation" "productivity" "files" "home" "monitoring" ];
  usedCategories = lib.unique (map (s: s.category) listedServices);
  categories =
    (lib.filter (c: lib.elem c usedCategories) categoryOrder)
    ++ lib.sort (a: b: a < b) (lib.filter (c: !lib.elem c categoryOrder) usedCategories);
  inCategory =
    c:
    lib.sort (a: b: if a.order != b.order then a.order < b.order else a.displayName < b.displayName) (
      lib.filter (s: s.category == c) listedServices
    );

  # Page data, kept separate from the markup (index.html.mustache) and rendered at build time.
  data = {
    hostCount = fleet.hosts;
    serviceCount = builtins.length services;
    hasMore = moreCount > 0;
    inherit moreCount;
    categories = map (c: {
      name = c;
      services = map (s: { inherit (s) displayName homepage; }) (inCategory c);
    }) categories;
  };
in
runCommandLocal "bphenriques.com" { nativeBuildInputs = [ mustache-go ]; } ''
  cp -r ${./site} "$out"
  chmod -R u+w "$out"
  mustache ${writeText "data.json" (builtins.toJSON data)} "$out/index.html.mustache" > "$out/index.html"
  rm "$out/index.html.mustache"
''
