{ lib, runCommandLocal, writeText, fetchurl, mustache-go, fleet }:
let
  services = lib.attrValues fleet.services;
  listed = lib.sort (a: b: a.order < b.order || a.order == b.order && a.displayName < b.displayName) (
    lib.filter (s: s.listed) services
  );

  # Unknown categories go last, alphabetically.
  categoryOrder = [ "identity" "media" "media automation" "productivity" "files" "home" "monitoring" ];
  rank = c: lib.lists.findFirstIndex (x: x == c) (builtins.length categoryOrder) categoryOrder;
  categories = lib.sort (a: b: rank a < rank b || rank a == rank b && a < b) (lib.unique (map (s: s.category) listed));

  data = {
    hostCount = fleet.hosts;
    serviceCount = builtins.length services;
    moreCount = builtins.length services - builtins.length listed;
    categories = map (name: { inherit name; services = lib.filter (s: s.category == name) listed; }) categories;
  };

  # IBM's official Latin subset (OFL-1.1).
  plexMono = weight: hash: fetchurl {
    url = "https://cdn.jsdelivr.net/npm/@ibm/plex-mono@2.5.0/fonts/split/woff2/IBMPlexMono-${weight}-Latin1.woff2";
    inherit hash;
  };
in
runCommandLocal "bphenriques.com" { nativeBuildInputs = [ mustache-go ]; } ''
  cp -r --no-preserve=mode ${./site} "$out"
  mustache ${writeText "data.json" (builtins.toJSON data)} ${./index.html.mustache} > "$out/index.html"
  install -Dm644 ${plexMono "Regular" "sha256-6Jk9lGZJudAaux7QbVdLGdjqPma1w5SGAtszXETBjlY="} "$out/fonts/IBMPlexMono-Regular.woff2"
  install -Dm644 ${plexMono "SemiBold" "sha256-t6zQUEGrZfO3A54hjd2JMGXhGgfoXqhQGUcxUqUba30="} "$out/fonts/IBMPlexMono-SemiBold.woff2"
''
