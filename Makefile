###############################
# Common defaults/definitions #
###############################

comma := ,

# Checks two given strings for equality.
eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)




######################
# Project parameters #
######################

VERSION ?= $(strip $(shell grep -m1 'version = "' Cargo.toml | cut -d '"' -f2))

IMAGE ?= ghcr.io/rust-lang-ua/ukrustacean




###########
# Aliases #
###########


all: fmt lint test docs


docs: cargo.doc


fmt: cargo.fmt


image: docker.image


lint: cargo.lint


test: test.cargo


up: cargo.run




##################
# Cargo commands #
##################

# Generate crates documentation from Rust sources.
#
# Usage:
#	make cargo.doc [private=(yes|no)] [open=(yes|no)] [clean=(no|yes)]

cargo.doc:
ifeq ($(clean),yes)
	@rm -rf target/doc/
endif
	cargo doc --all-features \
		$(if $(call eq,$(private),no),,--document-private-items) \
		$(if $(call eq,$(open),no),,--open)


# Format Rust sources with rustfmt.
#
# Usage:
#	make cargo.fmt [check=(no|yes)]

cargo.fmt:
	cargo +nightly fmt --all $(if $(call eq,$(check),yes),-- --check,)


# Lint Rust sources with Clippy.
#
# Usage:
#	make cargo.lint

cargo.lint:
	cargo clippy --all-features -- -D warnings


# Run project Rust sources with Cargo.
#
# Usage:
#	make cargo.run

cargo.run:
	cargo run


cargo.test: test.cargo




####################
# Testing commands #
####################

# Run Rust tests of project.
#
# Usage:
#	make test.cargo

test.cargo:
	cargo test --all-features




###################
# Docker commands #
###################

# Build project Docker image.
#
# Usage:
#	make docker.build [tag=($(VERSION)|<tag>)]
#	                  [debug=(yes|no)] [no-cache=(no|yes)]

docker.image:
	docker build --network=host --force-rm \
		$(if $(call eq,$(no-cache),yes),--no-cache --pull,) \
		--build-arg rustc_mode=$(if $(call eq,$(debug),no),release,debug) \
		--build-arg rustc_opts=$(if $(call eq,$(debug),no),--release,) \
		--label org.opencontainers.image.source=$(strip \
			https://github.com/rust-lang-ua/ukrustacean) \
		--label org.opencontainers.image.revision=$(strip \
			$(shell git show --pretty=format:%H --no-patch)) \
		--label org.opencontainers.image.version=$(strip $(VERSION)) \
		-t $(IMAGE):$(or $(tag),$(VERSION)) ./
# TODO: Use $(shell git describe --tags --dirty) as version label.


# Manually push Docker image to container registry.
#
# Usage:
#	make docker.push [tags=($(VERSION)|<docker-tag-1>[,<docker-tag-2>...])]

docker.push:
	$(foreach tag,$(subst $(comma), ,$(or $(tags),$(VERSION))),\
		$(call docker.push.do,$(tag)))
define docker.push.do
	$(eval tag := $(strip $(1)))
	docker push $(IMAGE):$(tag)
endef


# Tag project Docker image with given tags.
#
# Usage:
#	make docker.tag [of=($(VERSION)|<tag>)]
#	                [tags=($(VERSION)|<with-t1>[,<with-t2>...])]

docker.tag:
	$(foreach tag,$(subst $(comma), ,$(or $(tags),$(VERSION))),\
		$(call docker.tag.do,$(tag)))
define docker.tag.do
	$(eval tag := $(strip $(1)))
	docker tag $(IMAGE):$(or $(of),$(VERSION)) $(IMAGE):$(tag)
endef


# Save project Docker images to a tarball file.
#
# Usage:
#	make docker.tar [to-file=(.cache/image.tar|<file-path>)]
#	                [tags=($(VERSION)|<docker-tag-1>[,<docker-tag-2>...])]

docker-tar-file = $(or $(to-file),.cache/image.tar)

docker.tar:
	@mkdir -p $(dir $(docker-tar-file))
	docker save -o $(docker-tar-file) \
		$(foreach tag,$(subst $(comma), ,$(or $(tags),$(VERSION))),\
			$(IMAGE):$(tag))


# Load project Docker images from a tarball file.
#
# Usage:
#	make docker.untar [from-file=(.cache/image.tar|<file-path>)]

docker.untar:
	docker load -i $(or $(from-file),.cache/image.tar)




##################
# .PHONY section #
##################

.PHONY: all docs fmt image lint test up \
        cargo.doc cargo.fmt cargo.lint cargo.run cargo.test \
        docker.image docker.push docker.tag docker.tar docker.untar \
        test.cargo
