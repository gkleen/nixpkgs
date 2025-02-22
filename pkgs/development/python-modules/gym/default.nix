{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  numpy,
  cloudpickle,
  gym-notices,
  importlib-metadata,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "gym";
  version = "0.26.2";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "openai";
    repo = pname;
    tag = version;
    hash = "sha256-uJgm8l1SxIRC5PV6BIH/ht/1ucGT5UaUhkFMdusejgA=";
  };

  propagatedBuildInputs = [
    cloudpickle
    numpy
    gym-notices
  ] ++ lib.optionals (pythonOlder "3.10") [ importlib-metadata ];

  # The test needs MuJoCo that is not free library.
  doCheck = false;

  pythonImportsCheck = [ "gym" ];

  meta = with lib; {
    description = "Toolkit for developing and comparing your reinforcement learning agents";
    homepage = "https://gym.openai.com/";
    license = licenses.mit;
    maintainers = with maintainers; [ hyphon81 ];
  };
}
