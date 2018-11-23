{ stdenv, fetchFromGitHub, fetchurl, runCommand
, jdk10, ant
, jre10, makeWrapper
, javaPackages
}:

let
  versions = {
    gcs = {
      repo = "gcs";
      version = "4.11.1";
      sha256 = "0as678ig0vsg40zlfcscgb95a8501fa46hd7v3g87chnn8nm7riv";
    };
    appleStubs = {
      repo = "apple_stubs";
      version = "4.3.0";
      sha256 = "0m1qw30b19s04hj7nch1mbvv5s698g5dr1d1r7r07ykvk1yh7zsa";
    };
    toolkit = {
      repo = "toolkit";
      sha256 = "0zcdbnqdrc5753b99gnl102cvb7df6wlpxvgnsys0gkqi6dahq97";
    };
    library = {
      repo = "gcs_library";
      sha256 = "1y4rsv89mmf5jx43fz7lknjaw7ikydl8ynh2hwfqfwh35i5z706j";
    };
  };

  fetchSource = attrs@{ version ? versions.gcs.version, ... }: fetchFromGitHub {
    inherit (attrs) repo sha256;
    owner = "richardwilkes";
    rev = "gcs-${version}";
  };

  gcs = fetchSource versions.gcs;
  appleStubs = fetchSource versions.appleStubs;
  toolkit = fetchSource versions.toolkit;
  library = fetchSource versions.library;

  trove4j = stdenv.mkDerivation rec {
    name = "trove4j-${version}";
    version = "3.0.3";

    src = fetchurl {
    url = "mirror://maven/net/sf/trove4j/trove4j-${version}.jar";
      sha512 = "2slfxn88kglxpw9rs2a647mfr7413qvjs7ibvba07fwi8c81y1vp9r9qn8n9sjlkjc74hpn7s1sx0f88482svjjz1ls0g64abyiaf55";
    };

    phases = "installPhase";

    installPhase = ''
      mkdir -p $out/share/java
      cp $src $out/share/java/trove4j-${version}.jar
    '';
  };
in stdenv.mkDerivation rec {
  name = "gcs-${version}";
  inherit (versions.gcs) version;

  src = runCommand "${name}-src" { preferLocalBuild = true; } ''
    mkdir -p $out
    cd $out

    cp -r ${gcs} gcs
    cp -r ${appleStubs} apple_stubs
    cp -r ${toolkit} toolkit
    cp -r ${library} gcs_library
  '';

  buildInputs = [ jdk10 jre10 ant makeWrapper trove4j ];
  buildPhase = ''
    set -x

    cd apple_stubs
    ant

    cd ../toolkit
    ant -v -Dbuild.sysclasspath=first
  
    cd ../gcs
    ant

    cd ..
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/java

    find gcs/libraries toolkit/libraries apple_stubs/ \( -name '*.jar' -and -not -name '*-src.jar' \) -exec cp '{}' $out/share/java ';'
    
    makeWrapper ${jre10}/bin/java $out/bin/gcs \
      --set GCS_LIBRARY ${library} \
      --add-flags "-cp $out/share/java/gcs-${version}.jar com.trollworks.gcs.app.GCS"
  '';  

  meta = with stdenv.lib; {
    description = "A stand-alone, interactive, character sheet editor for the GURPS 4th Edition roleplaying game system";
    homepage = http://gurpscharactersheet.com/;
    license = licenses.mpl20;
    platforms = platforms.all;
    maintainers = with maintainers; [];
  };
}
