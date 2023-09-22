# Maintainer: Granottier Redemptor <omedaan11@gmail.com>
pkgname=video-stipe-preview
pkgver=1
pkgrel=1
pkgdesc="This is a script that generates a stripe video preview"
arch=('x86_64')
url=""
license=('GPL')
groups=()
depends=('coreutils' 'ffmpeg' 'bash' 'sed' 'grep')
provides=('video_strip_preview')
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("$pkgname-$pkgver.tar.gz"
        "$pkgname-$pkgver.patch")
noextract=()
md5sums=()
validpgpkeys=()

prepare() {
	cd "$pkgname-$pkgver"
	patch -p1 -i "$srcdir/$pkgname-$pkgver.patch"
}

build() {
	cd "$pkgname-$pkgver"
	./configure --prefix=/usr
	make
}

check() {
	cd "$pkgname-$pkgver"
	make -k check
}

package() {
	cd "$pkgname-$pkgver"
	make DESTDIR="$pkgdir/" install
}
