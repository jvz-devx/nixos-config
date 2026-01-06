{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonApplication rec {
  pname = "sqlit-tui";
  version = "1.1.7";

  src = fetchFromGitHub {
    owner = "Maxteabag";
    repo = "sqlit";
    rev = "v${version}";
    hash = "sha256-1B+IM67+q74JNwn6g4Bhvkl4SOMNuAv7rQ0JJXpmZ5s=";
  };

  # Relax dependency on textual-fastdatatable as nixpkgs currently has 0.12.0
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "textual-fastdatatable>=0.14.0" "textual-fastdatatable>=0.12.0"
  '';

  # sqlit doesn't use a standard build system in some versions, but 1.1.7 should have pyproject.toml
  format = "pyproject";

  nativeBuildInputs = with python3Packages; [
    hatchling
    hatch-vcs
  ];

  propagatedBuildInputs = with python3Packages; [
    textual
    click
    rich
    pyyaml
    keyring
    cryptography
    pyperclip
    docker
    textual-fastdatatable
    # Common drivers
    psycopg2
    requests
  ];

  # No tests in the source distribution usually
  doCheck = false;

  meta = with lib; {
    description = "A user-friendly TUI for SQL databases";
    homepage = "https://github.com/Maxteabag/sqlit";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "sqlit";
  };
}
