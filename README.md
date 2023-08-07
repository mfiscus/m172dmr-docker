# M172DMR Docker Image

This Debian Linux based Docker image allows you to run [juribeparada's](https://github.com/juribeparada) [M172DMR](https://github.com/juribeparada/MMDVM_CM/tree/master/M172DMR) without having to configure any files or compile any code.

This is a currently a single-arch image and will only run on armv7 devices.

| Image Tag             | Architectures           | Base Image         | 
| :-------------------- | :-----------------------| :----------------- | 
| buster-slim, debian   | armv7                   | Debian Buster      | 

## Compatibility

m172dmr-docker requires certain variables be defined in your docker run command or docker-compose.yml (recommended) so it can automate the configuration upon bootup.
```bash
CALLSIGN=your_callsign
EMAIL=your@email.com
URL=your_domain.com
XLXNUM=XLX000
```

**For for cross-mode transcoding support you must also run a separate instance of [m172dmr-docker](https://github.com/kk7mnz/tcd-docker)

## Usage

Command Line:

```bash
docker run --name=m172dmr -v /opt/m172dmr:/config -e "CALLSIGN=M17-???" -e "EMAIL=your@email.com" -e "URL=your_domain.com" mfiscus/m172dmr:latest
```

Using [Docker Compose](https://docs.docker.com/compose/) (recommended):

```yml
version: '3.8'

services:
  m172dmr:
    image: mfiscus/m172dmr:latest
    container_name: m172dmr
    hostname: m172dmr_container
    environment:
      # only set CALLHOME to true once your are certain your configuration is correct
      # make sure you backup your callinghome.php file (which should be located on the docker host in /opt/m172dmr/) 
      CALLHOME: 'false' 
      CALLSIGN: 'your_callsign'
      EMAIL: 'your@email.com'
      URL: 'your_domain.com'
      PORT: '80'
      XLXNUM: 'XLX000'
      COUNTRY: 'United States'
      DESCRIPTION: 'My m172dmr-docker reflector'
      # Define how many modules you require
      MODULES: '4'
      # Name your modules however you like (container only supports naming first 4)
      MODULEA: 'Main'
      MODULEB: 'D-Star'
      MODULEC: 'DMR'
      MODULED: 'YSF'
      TZ: 'UTC'
    networks:
      - proxy
    volumes:
      # local directory where state and config files (including callinghome.php) will be saved
      - /opt/m172dmr:/config
    restart: unless-stopped
```

Using [Docker Compose](https://docs.docker.com/compose/) with [ambed-docker](https://github.com/mfiscus/ambed-docker) (support for cross-mode transcoding):

```yml
version: '3.8'

services:
  ambed:
    image: mfiscus/ambed:latest
    container_name: ambed
    hostname: ambed_container
    networks:
      - proxy
    privileged: true
    restart: unless-stopped

  m172dmr:
    image: mfiscus/m172dmr:latest
    container_name: m172dmr
    hostname: m172dmr_container
    depends_on:
      ambed:
        condition: service_healthy
        restart: true
    environment:
      # only set CALLHOME to true once your are certain your configuration is correct
      # make sure you backup your callinghome.php file (which should be located on the docker host in /opt/m172dmr/) 
      CALLHOME: 'false' 
      CALLSIGN: 'your_callsign'
      EMAIL: 'your@email.com'
      URL: 'your_domain.com'
      PORT: '80'
      XLXNUM: 'XLX000'
      COUNTRY: 'United States'
      DESCRIPTION: 'My m172dmr-docker reflector'
      # Define how many modules you require
      MODULES: '4'
      # Name your modules however you like (container only supports naming first 4)
      MODULEA: 'Main'
      MODULEB: 'D-Star'
      MODULEC: 'DMR'
      MODULED: 'YSF'
      TZ: 'UTC'
    networks:
      - proxy
    volumes:
      # local directory where state and config files (including callinghome.php) will be saved
      - /opt/m172dmr:/config
    restart: unless-stopped
```

Using [Docker Compose](https://docs.docker.com/compose/) with [ambed-docker](https://github.com/mfiscus/ambed-docker) and [traefik](https://github.com/traefik/traefik) (reverse proxy):

```yml
version: '3.8'

services:
  traefik:
    image: traefik:latest
    container_name: "traefik"
    hostname: traefik_container
    # Enables the web UI and tells Traefik to listen to docker
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      # logging
      - --accesslog=true
      #- --log.level=DEBUG
      - --accesslog.filepath=/var/log/traefik.log
      - --accesslog.bufferingsize=100
      # create entrypoints
      - --entrypoints.www.address=:80/tcp
      - --entrypoints.traefik.address=:8080/tcp
      # m172dmr
      - --entrypoints.m172dmr-http.address=:80/tcp
      - --entrypoints.m172dmr-repnet.address=:8080/udp
      - --entrypoints.m172dmr-repnet.udp.timeout=86400s
      - --entrypoints.m172dmr-urfcore.address=:10001/udp
      - --entrypoints.m172dmr-urfcore.udp.timeout=86400s
      - --entrypoints.m172dmr-interlink.address=:10002/udp
      - --entrypoints.m172dmr-interlink.udp.timeout=86400s
      - --entrypoints.m172dmr-ysf.address=:42000/udp
      - --entrypoints.m172dmr-ysf.udp.timeout=86400s
      - --entrypoints.m172dmr-dextra.address=:30001/udp
      - --entrypoints.m172dmr-dextra.udp.timeout=86400s
      - --entrypoints.m172dmr-dplus.address=:20001/udp
      - --entrypoints.m172dmr-dplus.udp.timeout=86400s
      - --entrypoints.m172dmr-dcs.address=:30051/udp
      - --entrypoints.m172dmr-dcs.udp.timeout=86400s
      - --entrypoints.m172dmr-dmr.address=:8880/udp
      - --entrypoints.m172dmr-dmr.udp.timeout=86400s
      - --entrypoints.m172dmr-mmdvm.address=:62030/udp
      - --entrypoints.m172dmr-mmdvm.udp.timeout=86400s
      - --entrypoints.m172dmr-icom-terminal-1.address=:12345/udp
      - --entrypoints.m172dmr-icom-terminal-1.udp.timeout=86400s
      - --entrypoints.m172dmr-icom-terminal-2.address=:12346/udp
      - --entrypoints.m172dmr-icom-terminal-2.udp.timeout=86400s
      - --entrypoints.m172dmr-icom-dv.address=:40000/udp
      - --entrypoints.m172dmr-icom-dv.udp.timeout=86400s
      - --entrypoints.m172dmr-yaesu-imrs.address=:21110/udp
      - --entrypoints.m172dmr-yaesu-imrs.udp.timeout=86400s
    ports:
      # traefik ports
      - 80:80/tcp # The www port
      - 8080:8080/tcp # The Web UI (enabled by --api.insecure=true)
      # m172dmr ports
      - 80:80/tcp # http
      - 8080:8080/udp # repnet
      - 10001:10001/udp # urfcore
      - 10002:10002/udp # urf interlink
      - 42000:42000/udp # ysf
      - 30001:30001/udp # dextra
      - 20001:20001/udp # dplus
      - 30051:30051/udp # dcs
      - 8880:8880/udp # dmr
      - 62030:62030/udp # mmdvm
      - 12345:12345/udp # icom terminal 1
      - 12346:12346/udp # icom terminal 2
      - 40000:40000/udp # icom dv
      - 21110:21110/udp # yaesu imrs
    networks:
      - proxy
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  ambed:
    image: mfiscus/ambed:latest
    container_name: ambed
    hostname: ambed_container
    depends_on:
      traefik:
        condition: service_started
    networks:
      - proxy
    privileged: true
    restart: unless-stopped

  m172dmr:
    image: mfiscus/m172dmr:latest
    container_name: m172dmr
    hostname: m172dmr_container
    depends_on:
      traefik:
        condition: service_started
      ambed:
        condition: service_healthy
        restart: true
    labels:
      - "traefik.m172dmr-http.rule=HostRegexp:your_domain.com,{catchall:.*}"
      - "traefik.m172dmr-http.priority=1"
      - "traefik.docker.network=docker_proxy"
      # Explicitly tell Traefik to expose this container
      - "traefik.enable=true"
      # The domain the service will respond to
      - "traefik.http.routers.m172dmr-http.rule=Host(`your_domain.com`)"
      # Allow request only from the predefined entry point named "m172dmr-http"
      - "traefik.http.routers.m172dmr-http.entrypoints=m172dmr-http"
      # Specify port m172dmr http port
      - "traefik.http.services.m172dmr-http.loadbalancer.server.port=80"
      # test alternate http port
      - "traefik.http.routers.m172dmr-http.service=m172dmr-http"
      # UDP routers
      # repnet
      - "traefik.udp.routers.m172dmr-repnet.entrypoints=m172dmr-repnet"
      - "traefik.udp.routers.m172dmr-repnet.service=m172dmr-repnet"
      - "traefik.udp.services.m172dmr-repnet.loadbalancer.server.port=8080"
      # urfcore
      - "traefik.udp.routers.m172dmr-urfcore.entrypoints=m172dmr-urfcore"
      - "traefik.udp.routers.m172dmr-urfcore.service=m172dmr-urfcore"
      - "traefik.udp.services.m172dmr-urfcore.loadbalancer.server.port=10001"
      # urf interlink
      - "traefik.udp.routers.m172dmr-interlink.entrypoints=m172dmr-interlink"
      - "traefik.udp.routers.m172dmr-interlink.service=m172dmr-interlink"
      - "traefik.udp.services.m172dmr-interlink.loadbalancer.server.port=10002"
      # m172dmr-ysf
      - "traefik.udp.routers.m172dmr-ysf.entrypoints=m172dmr-ysf"
      - "traefik.udp.routers.m172dmr-ysf.service=m172dmr-ysf"
      - "traefik.udp.services.m172dmr-ysf.loadbalancer.server.port=42000"
      # m172dmr-dextra
      - "traefik.udp.routers.m172dmr-dextra.entrypoints=m172dmr-dextra"
      - "traefik.udp.routers.m172dmr-dextra.service=m172dmr-dextra"
      - "traefik.udp.services.m172dmr-dextra.loadbalancer.server.port=30001"
      # m172dmr-dplus
      - "traefik.udp.routers.m172dmr-dplus.entrypoints=m172dmr-dplus"
      - "traefik.udp.routers.m172dmr-dplus.service=m172dmr-dplus"
      - "traefik.udp.services.m172dmr-dplus.loadbalancer.server.port=20001"
      # dcs
      - "traefik.udp.routers.m172dmr-dcs.entrypoints=m172dmr-dcs"
      - "traefik.udp.routers.m172dmr-dcs.service=m172dmr-dcs"
      - "traefik.udp.services.m172dmr-dcs.loadbalancer.server.port=30051"
      # dmr
      - "traefik.udp.routers.m172dmr-dmr.entrypoints=m172dmr-dmr"
      - "traefik.udp.routers.m172dmr-dmr.service=m172dmr-dmr"
      - "traefik.udp.services.m172dmr-dmr.loadbalancer.server.port=8880"
      # mmdvm
      - "traefik.udp.routers.m172dmr-mmdvm.entrypoints=m172dmr-mmdvm"
      - "traefik.udp.routers.m172dmr-mmdvm.service=m172dmr-mmdvm"
      - "traefik.udp.services.m172dmr-mmdvm.loadbalancer.server.port=62030"
      # icom-terminal-1
      - "traefik.udp.routers.m172dmr-icom-terminal-1.entrypoints=m172dmr-icom-terminal-1"
      - "traefik.udp.routers.m172dmr-icom-terminal-1.service=m172dmr-icom-terminal-1"
      - "traefik.udp.services.m172dmr-icom-terminal-1.loadbalancer.server.port=12345"
      # icom-terminal-2
      - "traefik.udp.routers.m172dmr-icom-terminal-2.entrypoints=m172dmr-icom-terminal-2"
      - "traefik.udp.routers.m172dmr-icom-terminal-2.service=m172dmr-icom-terminal-2"
      - "traefik.udp.services.m172dmr-icom-terminal-2.loadbalancer.server.port=12346"
      # icom-dv
      - "traefik.udp.routers.m172dmr-icom-dv.entrypoints=m172dmr-icom-dv"
      - "traefik.udp.routers.m172dmr-icom-dv.service=m172dmr-icom-dv"
      - "traefik.udp.services.m172dmr-icom-dv.loadbalancer.server.port=40000"
      # yaesu-imrs
      - "traefik.udp.routers.m172dmr-yaesu-imrs.entrypoints=m172dmr-yaesu-imrs"
      - "traefik.udp.routers.m172dmr-yaesu-imrs.service=m172dmr-yaesu-imrs"
      - "traefik.udp.services.m172dmr-yaesu-imrs.loadbalancer.server.port=21110"
    environment:
      # only set CALLHOME to true once your are certain your configuration is correct
      # make sure you backup your callinghome.php file (which should be located on the docker host in /opt/m172dmr/) 
      CALLHOME: 'false' 
      CALLSIGN: 'your_callsign'
      EMAIL: 'your@email.com'
      URL: 'your_domain.com'
      PORT: '80'
      XLXNUM: 'XLX000'
      COUNTRY: 'United States'
      DESCRIPTION: 'My m172dmr-docker reflector'
      # Define how many modules you require
      MODULES: '4'
      # Name your modules however you like (container only supports naming first 4)
      MODULEA: 'Main'
      MODULEB: 'D-Star'
      MODULEC: 'DMR'
      MODULED: 'YSF'
      TZ: 'UTC'
    networks:
      - proxy
    volumes:
      # local directory where state and config files (including callinghome.php) will be saved
      - /opt/m172dmr:/config
    restart: unless-stopped
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.

* `-v` - maps a local directory used for backing up state and configuration files (including callinghome.php) **required**
* `-e` - used to set environment variables in the container

## License

Copyright (C) 2020-2022 Thomas A. Early N7TAE
Copyright (C) 2023 mfiscus KK7MNZ

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
