[GITHUB](https://github.com/Tob1as/docker-tools)  
  
# Tools

Tools collection

All Images are Multiarch (AMD64, ARM64 and ARM) builds and in the following Container Registries:
* [`ghcr.io/tob1as/docker-tools:<TAG>`](https://github.com/Tob1as/docker-tools/pkgs/container/tools)
* [`tobi312/tools:<TAG>`](https://hub.docker.com/r/tobi312/tools)
* [`quay.io/tobi312/tools:<TAG>`](https://quay.io/repository/tobi312/tools)

Tools/Tags:
* [`adminer`](#)
* [`autossh`](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_docker-compose/autossh.yml)
* [`azcopy`](#)
* [`c-mqtt-forwarder`](#)
* [`dnsmasq`](#dnsmasq)
* [`easy-rsa`](#easy-rsa)
* [`figlet`](#figlet)
* [`htpasswd`](#htpasswd)
* [`keepalived`](#)
* [`kiwiirc`](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_docker-compose/ircd.yml#L62)
* [`mqtt-board`](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_docker-compose/mqtt-board.yml)
* [`mqtt-client`](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_docker-compose/mqtt-client.yml)
* [`mqtt-forwarder`](#)
* [`php-fpm-exporter`](#)
* [`postgres-exporter`](#)
* [`prometheus-mosquitto-exporter`](#)
* [`prometheus-mqtt-transport`](#)
* [`proxyscotch`](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_docker-compose/hoppscotch.yml)
* [`squid`](#)
* [`static-curl`](#)
* [`static-jq`](#)
* [`static-xq`](#)
* [`static-yq`](#)
* [`static-kubectl`](#)
* [`static-helm`](#)
* NGINX (static):
  * [`static-nginx`](#)
  * [`static-nginx-unprivileged`](#)
* [`static-ssh-tools`](#)
  * ssh, sftp, scp, ssh-keygen
  * sshpass
  * rsync
  * autossh
* ToolBox:
  * [`toolbox`](#toolbox)
  * [`toolbox-extended`](#toolbox)
* Deprecated:
  * [`adminerevo`]() - Use adminer!
  * [`pgadmin4`](https://www.pgadmin.org/download/pgadmin-4-container/) - Use now offical Docker build!
  * [`irc-exporter`](https://github.com/dgl/ircd_exporter) - Use now offical Docker build!
  * [`vwmetrics`](https://github.com/Tricked-dev/vwmetrics) - Use now offical Docker build!

## figlet 

[FIGlet](http://www.figlet.org/) is a computer program that generates text banners.

This Docker Image is based on latest AlpineLinux, see [Dockerfile](https://github.com/Tob1as/docker-tools/blob/main/figlet.multiarch.alpine.Dockerfile) for more details.

### Example
```sh
docker run --rm --name figlet -it tobi312/tools:figlet 'Hello :D'
```
Output:
```
 _   _      _ _           ____
| | | | ___| | | ___    _|  _ \
| |_| |/ _ \ | |/ _ \  (_) | | |
|  _  |  __/ | | (_) |  _| |_| |
|_| |_|\___|_|_|\___/  (_)____/

```

## htpasswd

[htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html) create username password information of a web server.

This Docker Image is based on latest AlpineLinux, see [Dockerfile](https://github.com/Tob1as/docker-tools/blob/main/htpasswd.multiarch.alpine.Dockerfile) for more details.

### Example
```sh
docker run --rm -it tobi312/tools:htpasswd -bn username passw0rd
```
Output:
```
username:$apr1$Sk1pFYwB$ivgO9asJe4WkalyC7L5TV0
```


## ToolBox

Toolbox with git, wget, curl, nano, netcat and more.

This Docker Image is based on latest AlpineLinux, see [Dockerfile](https://github.com/Tob1as/docker-tools/blob/main/toolbox.multiarch.alpine.Dockerfile) and [Dockerfile (extended)](https://github.com/Tob1as/docker-tools/blob/main/toolbox_extended.multiarch.alpine.Dockerfile) for more details.

### Example for Docker
```sh
# start
docker run --rm --name toolbox -d tobi312/tools:toolbox
# exec
docker exec -it toolbox sh
# use (example: check port is open)
nc -zv -w 3 <HOST> <PORT>
```

### Example for Docker-Compose

<details>
<summary>Create file `toolbox.yml` with this content: (click)</summary>
<p>

```yml
version: '2.4'
services:

  toolbox:
    image: tobi312/tools:toolbox
    #image: tobi312/tools:toolbox-extended
    container_name: toolbox
    restart: unless-stopped
    #user: "1000:1000"  # format: "${UID}:${GID}"
    #entrypoint: [ "/bin/sh", "-c", "--" ]
    #command: [ "while true; do sleep 60; done;" ] 
```
and then:
```sh
# start
docker-compose -f toolbox.yml up -d
# exec (you can use sh or bash)
docker-compose -f toolbox.yml exec toolbox sh
# or
docker exec -it toolbox sh
# use (example: check port is open)
nc -zv -w 3 <HOST> <PORT>
```

</p>
</details>

### Example for Kubernetes

<details>
<summary>Create file `toolbox.yaml` with this content: (click)</summary>
<p>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: toolbox
  namespace: default
spec:
  containers:
  - name: toolbox
    image: tobi312/tools:toolbox
    resources:
      requests:
        memory: "128Mi"
        cpu: "0.1"
      limits:
        memory: "512Mi"
        cpu: "0.5"
```
and then:
```sh
# start
kubectl apply -f toolbox.yaml
# exec
kubectl exec -it pod/toolbox -- sh
# use (example: check port is open)
nc -zv -w 3 <HOST> <PORT>
```
  
Or [example](https://github.com/Tob1as/docker-kubernetes-collection/blob/master/examples_k8s/toolbox.yaml) for Deployment.

</p>
</details>

## dnsmasq

[dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) is a lightweight dns and dhcp server.

### Example for Docker-Compose

<details>
<summary>Create file `docker-compose.yml` with this content: (click)</summary>
<p>

```yaml
version: "2.4"
services:

  dnsmasq:
    image: tobi312/tools:dnsmasq
    container_name: dnsmasq
    restart: unless-stopped
    ports:
      - 53:53/tcp # DNS
      - 53:53/udp # DNS
      - 67:67/udp # DHCP Server
      #- 68:68/udp # DHCP Client
      #- 69:69/udp # TFTP
    volumes:
      - ./dnsmasq/:/etc/dnsmasq.d/:rw  # add your config files in this folder
    #network_mode: host
    cap_add:
      - 'NET_ADMIN'
```
</p>
</details>

## easy-rsa

[easy-rsa](https://github.com/OpenVPN/easy-rsa) is a CLI utility to build and manage a PKI CA.

* offical [Docs](https://easy-rsa.readthedocs.io)
* [Dockerfile](https://github.com/Tob1as/docker-tools/blob/main/easy-rsa.multiarch.alpine.Dockerfile)

### Example(s)

```sh
# help
docker run --rm --name easy-rsa -it tobi312/tools:easy-rsa-3.1.7 help
```

<details>
<summary>Example (1) - root-ca & certs:  (click)</summary>
<p>

```sh
# Preparation
mkdir ~/data_easyrsa
# IMPORANT: Execute all Command from this/next Folder !!
cd ~/data_easyrsa

# root-ca
# init pki
docker run --rm --name easy-rsa -v ${PWD}:/easyrsa:rw -it tobi312/tools:easy-rsa-3.1.7 init-pki
# download "vars"-File
curl -sL https://github.com/OpenVPN/easy-rsa/raw/master/easyrsa3/vars.example -o ./pki/vars
# now EDIT "vars"-File in ./pki
# and then build ca:
docker run --rm --name easy-rsa -v ${PWD}:/easyrsa:rw -it tobi312/tools:easy-rsa-3.1.7 build-ca

# Server Cert (repeat this steps for other domains)
# create server cert request
docker run --rm --name easy-rsa -v ${PWD}:/easyrsa:rw -it tobi312/tools:easy-rsa-3.1.7 --subject-alt-name="DNS:example.com,DNS:*.example.com,IP:192.168.1.100" gen-req example-com nopass
# sign server cert
docker run --rm --name easy-rsa -v ${PWD}:/easyrsa:rw -it tobi312/tools:easy-rsa-3.1.7 sign-req server example-com
# check cert
openssl verify -verbose -CAfile ${PWD}/pki/ca.crt ${PWD}/pki/issued/example-com.crt
openssl x509 -noout -text -in ${PWD}/pki/issued/example-com.crt
```
</p>
</details>


<details>
<summary>Example (2) - root-ca, intermediate-ca & certs:  (click)</summary>
<p>

**Preparation**:
```sh
mkdir ~/data_easyrsa
# IMPORANT: Execute all Command from this/next Folder !!
cd ~/data_easyrsa
```

**root-ca**:
```sh
# init pki (need "soft" to write in mounted volume subpath "/easyrsa/root-ca" instead "/easyrsa/pki")
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/root-ca" -v ${PWD}/root-ca/:/easyrsa/root-ca:rw -it tobi312/tools:easy-rsa-3.1.7 init-pki soft
# ASK: Confirm removal: yes

# download "vars"-File
curl -sL https://github.com/OpenVPN/easy-rsa/raw/master/easyrsa3/vars.example -o ${PWD}/root-ca/vars
# now EDIT "vars"-File in ./root-ca
# and then build ca:
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/root-ca" -v ${PWD}/root-ca/:/easyrsa/root-ca:rw -it tobi312/tools:easy-rsa-3.1.7 build-ca
# ASK: Enter New CA Key Passphrase:
# ASK: Common Name (eg: your user, host, or server name) [Easy-RSA CA]: My Organization CA

# check/show content of root-ca "ca.crt" file
openssl x509 -noout -text -in ${PWD}/root-ca/ca.crt
```


**intermediate-ca** = subca:
```sh
# init pki (need "soft" to write in mounted volume subpath "/easyrsa/intermediate-ca" instead "/easyrsa/pki")
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/intermediate-ca" -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 init-pki soft
# ASK: Confirm removal: yes

# download "vars"-File
curl -sL https://github.com/OpenVPN/easy-rsa/raw/master/easyrsa3/vars.example -o ${PWD}/intermediate-ca/vars
# now EDIT "vars"-File in ./intermediate-ca
# and then build subca:
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/intermediate-ca" -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 build-ca subca
# ASK: Enter New CA Key Passphrase:
# ASK: Common Name (eg: your user, host, or server name) [Easy-RSA CA]: My Organization Sub-CA

# import subca in ca (Note: switch to root-ca):
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/root-ca" -v ${PWD}/root-ca/:/easyrsa/root-ca:rw -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 import-req /easyrsa/intermediate-ca/reqs/ca.req intermediate-ca

# sign subca with ca (Note: switch to root-ca)
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/root-ca" -v ${PWD}/root-ca/:/easyrsa/root-ca:rw -it tobi312/tools:easy-rsa-3.1.7 sign-req ca intermediate-ca
# ASK: Confirm request details: yes
# ASK: Enter pass phrase for /easyrsa/root-ca/private/ca.key:

# copy sign subca from root-ca to intermediate-ca folder
docker run --rm --name easy-rsa --entrypoint="" -v ${PWD}/root-ca/:/easyrsa/root-ca:rw -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 cp /easyrsa/root-ca/issued/intermediate-ca.crt /easyrsa/intermediate-ca/ca.crt
# or
cp ${PWD}/root-ca/issued/intermediate-ca.crt ${PWD}/intermediate-ca/ca.crt

# verify subca from ca
openssl verify -verbose -CAfile ${PWD}/root-ca/ca.crt ${PWD}/intermediate-ca/ca.crt
# check/show content of intermediate-ca "ca.crt" file
openssl x509 -noout -text -in ${PWD}/intermediate-ca/ca.crt


# copy subca and ca in one file called fullca.crt
cat ${PWD}/intermediate-ca/ca.crt ${PWD}/root-ca/ca.crt > ${PWD}/fullca.crt
```

**Server Cert** ... for Domain example.com:
```sh
# create server cert request
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/intermediate-ca" -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 --subject-alt-name="DNS:example.com,DNS:*.example.com,IP:192.168.1.100" gen-req example-com nopass
# ASK: Common Name (eg: your user, host, or server name) [example-com]:example.com

# sign server cert
docker run --rm --name easy-rsa -e EASYRSA_PKI="/easyrsa/intermediate-ca" -v ${PWD}/intermediate-ca/:/easyrsa/intermediate-ca:rw -it tobi312/tools:easy-rsa-3.1.7 sign-req server example-com
# ASK: Confirm request details: yes
# ASK: Enter pass phrase for /easyrsa/intermediate-ca/private/ca.key:

# verify cert from subca and ca
openssl verify -verbose -CAfile ${PWD}/fullca.crt ${PWD}/intermediate-ca/issued/example-com.crt
# check/show content of cert file
openssl x509 -noout -text -in ${PWD}/intermediate-ca/issued/example-com.crt

# repeat this steps for other domains
```

</p>
</details>

### Notes

<details>
<summary>Notes ...:  (click)</summary>
<p>

* instead `-e EASYRSA_PKI="/easyrsa/root-ca"` you can use in command `--pki-dir=/easyrsa/root-ca`
* Backup: execute `tar cvpzf backup_easyrsa_$(date '+%Y%m%d-%H%M').tar.gz .` in `data_easyrsa`-Folder!
* `docker run --rm --name easy-rsa --entrypoint="" -it tobi312/tools:easy-rsa-3.1.7 bash`
* linux: copy ca-certs into  `/usr/local/share/ca-certificates/` and execute `dpkg-reconfigure -f noninteractive ca-certificates`
* crlDistributionPoints: https://github.com/OpenVPN/easy-rsa/issues/71 & https://github.com/OpenVPN/easy-rsa/issues/472 & https://github.com/OpenVPN/easy-rsa/pull/15 & "/usr/share/easy-rsa/x509-types/COMMON
* more help: https://github.com/OpenVPN/easy-rsa/issues/190#issuecomment-6786936427 & https://documentation.abas.cloud/en/abas-installer/Zertifikate_en/index.html

</p>
</details>
