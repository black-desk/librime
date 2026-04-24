# fetch and build third party libraries from source via CMake FetchContent

rime_root = $(CURDIR)

ifndef NOPARALLEL
export MAKEFLAGS+=" -j$$(( $$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 8) + 1)) "
endif

build ?= build
prefix ?= $(rime_root)

.PHONY: all clean

all:
	cmake . -B$(build) \
	-DCMAKE_INSTALL_PREFIX=$(prefix) \
	-DCMAKE_BUILD_TYPE=Release \
	-DUSE_VENDORED_DEPS=ON \
	-DBUILD_STATIC=ON \
	-DBUILD_SHARED_LIBS=OFF

clean:
	rm -r $(build)/_deps || true
