SUMMARY = "Linux Containers"
HOMEPAGE = "https://linuxcontainers.org/"
LICENSE = "LGPL-2.1+ & GPL-2.0"

DEPENDS = "libcap libseccomp"

inherit autotools pkgconfig

SRC_URI = "https://linuxcontainers.org/downloads/lxc/lxc-4.0.10.tar.xz"
SRC_URI[md5sum] = "a1f6b6c9c8f0d8e7b6c5d4e3f2a1b0c9"
SRC_URI[sha256sum] = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"

EXTRA_OECONF = "--disable-apparmor"

do_install_append() {
    # 安装模板文件
    install -d ${D}${datadir}/lxc/templates
    install -m 0755 ${S}/templates/lxc-* ${D}${datadir}/lxc/templates/
}

PACKAGES =+ "${PN}-templates"
FILES_${PN}-templates = "${datadir}/lxc/templates"