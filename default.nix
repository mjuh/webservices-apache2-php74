{ nixpkgs ? (import ./common.nix).nixpkgs }:

with nixpkgs;

let
  inherit (builtins) concatMap getEnv toJSON;
  inherit (dockerTools) buildLayeredImage;
  inherit (lib) concatMapStringsSep firstNChars flattenSet dockerRunCmd mkRootfs;
  inherit (lib.attrsets) collect isDerivation;
  inherit (stdenv) mkDerivation;

  php74DockerArgHints = lib.phpDockerArgHints { php = php74; };

  rootfs = mkRootfs {
    name = "apache2-rootfs-php74";
    src = ./rootfs;
    inherit zlib curl coreutils findutils apacheHttpdmpmITK apacheHttpd
      mjHttpErrorPages s6 execline php74 logger;
    postfix = sendmail;
    ioncube = ioncube.v74;
    s6PortableUtils = s6-portable-utils;
    s6LinuxUtils = s6-linux-utils;
    mimeTypes = mime-types;
    libstdcxx = gcc-unwrapped.lib;
  };

in

pkgs.dockerTools.buildLayeredImage rec {
  name = "docker-registry.intr/webservices/apache2-php74";
  tag = "latest";
  contents = [
    rootfs
    apacheHttpd
    tzdata
    locale
    sendmail
    sh
    coreutils
    libjpeg_turbo
    jpegoptim
    (optipng.override{ inherit libpng ;})
    imagemagickBig
    ghostscript
    gifsicle nss-certs.unbundled zip
    gcc-unwrapped.lib
    glibc
    zlib
    mariadbConnectorC
    logger
  ]
  ++ collect isDerivation php74Packages;
  config = {
    Entrypoint = [ "${rootfs}/init" ];
    Env = [
      "TZ=Europe/Moscow"
      "TZDIR=${tzdata}/share/zoneinfo"
      "LOCALE_ARCHIVE_2_27=${locale}/lib/locale/locale-archive"
      "LOCALE_ARCHIVE=${locale}/lib/locale/locale-archive"
      "LC_ALL=en_US.UTF-8"
      "LD_PRELOAD=${jemalloc}/lib/libjemalloc.so"
    ];
    Labels = flattenSet rec {
      ru.majordomo.docker.arg-hints-json = builtins.toJSON php74DockerArgHints;
      ru.majordomo.docker.cmd = dockerRunCmd php74DockerArgHints "${name}:${tag}";
      ru.majordomo.docker.exec.reload-cmd = "${apacheHttpd}/bin/httpd -d ${rootfs}/etc/httpd -k graceful";
    };
  };
  extraCommands = ''
      set -xe
      ls
      mkdir -p etc
      mkdir -p bin
      mkdir -p usr/local
      mkdir -p opt
      ln -s ${php74} opt/php74
      ln -s /bin usr/bin
      ln -s /bin usr/sbin
      ln -s /bin usr/local/bin
      mkdir tmp
      chmod 1777 tmp
    '';
}
