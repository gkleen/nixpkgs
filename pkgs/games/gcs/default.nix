{ stdenv, fetchFromGitHub, runCommand
, jdk8, ant
, jre8, makeWrapper
, findutils
}:

let
  gcs = fetchFromGitHub {
    owner = "richardwilkes";
    repo = "gcs";
    rev = "gcs-4.10.0";
    sha256 = "1larn85s1imqja0mh3igb5ljk8a8aky1caypm672s1n6ps4pfa6q";
  };
  appleStubs = fetchFromGitHub {
    owner = "richardwilkes";
    repo = "apple_stubs";
    rev = "gcs-4.3.0";
    sha256 = "0m1qw30b19s04hj7nch1mbvv5s698g5dr1d1r7r07ykvk1yh7zsa";
  };
  toolkit = fetchFromGitHub {
    owner = "richardwilkes";
    repo = "toolkit";
    rev = "gcs-4.10.0";
    sha256 = "0mx5sjwzmpr0vry254l6mz3m7zkkwcac60qaz31cgi3k5pbk04xw";
  };
  library = fetchFromGitHub {
    owner = "richardwilkes";
    repo = "gcs_library";
    rev = "gcs-4.10.0";
    sha256 = "1fgpz0p21f5m28m4kgn9sa82w9d3zxvjx31dk10sqi8hy58ry04p";
  };
in stdenv.mkDerivation rec {
  name = "gcs-${version}";
  version = "4.10.0";

  src = runCommand "${name}-src" { preferLocalBuild = true; } ''
    mkdir -p $out
    cd $out

    cp -r ${gcs} gcs
    cp -r ${appleStubs} apple_stubs
    cp -r ${toolkit} toolkit
    cp -r ${library} gcs_library
  '';

  buildInputs = [ jdk8 jre8 ant makeWrapper ];
  buildPhase = ''
    cd apple_stubs
    ant

    cd ../toolkit
    ant
  
    cd ../gcs
    ant

    cd ..
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/java

    find gcs/libraries toolkit/libraries apple_stubs/ \( -name '*.jar' -and -not -name '*-src.jar' \) -exec cp '{}' $out/share/java ';'
    
    makeWrapper ${jre8}/bin/java $out/bin/gcs \
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
