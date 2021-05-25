#
# Build stage
#
FROM ubuntu:20.04 AS build-stage

ARG DEBIAN_FRONTEND=noninteractive
# Install dependencies
RUN set -xe; \
	apt-get update; \
	apt-get install --no-install-recommends -y \
		cmake make g++ protobuf-compiler patch \
		qtbase5-dev libqt5opengl5-dev libprotobuf-dev; \
	apt-get clean -y; \
	rm -rf /var/lib/apt/lists/*;

RUN useradd --create-home --shell /bin/bash default
WORKDIR /home/default
COPY . .
RUN set -xe; \
	mkdir build; \
	cd build; \
	cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..; \
	make autoref -j $(nproc)

##
## Run stage
##
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN set -xe; \
	apt-get update; \
	apt-get install --no-install-recommends -y \
		qtbase5-dev libqt5opengl5-dev libprotobuf-dev \
		x11vnc xvfb \
		tini ; \
	apt-get clean -y; \
	rm -rf /var/lib/apt/lists/*;

RUN useradd --create-home --shell /bin/bash default
WORKDIR /home/default

COPY --chown=default:default --from=build-stage /home/default/COPYING COPYING
COPY --chown=default:default --from=build-stage /home/default/LICENSE LICENSE
COPY --chown=default:default --from=build-stage /home/default/src/framework/strategy/lua src/framework/strategy/lua/
COPY --chown=default:default --from=build-stage /home/default/autoref autoref/
COPY --chown=default:default --from=build-stage /home/default/build/bin build/bin/
# COPY --chown just changes permissions on the inner folder. We need to aquire
# the outer one as well
RUN chown default:default build/
COPY --chown=default:default --from=build-stage /home/default/data data/
COPY --chown=default:default --from=build-stage /home/default/config config/
COPY --chown=default:default docker-entry.bash /

USER default

# Ports
# 5900 - vnc
# Ports used by SSL protocols are documented here
# https://ssl.robocup.org/league-software/
EXPOSE 5900
ENTRYPOINT ["tini", "--", "/docker-entry.bash"]
