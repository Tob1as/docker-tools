# Tools

Tools collection

All Images are Multiarch (AMD64, ARM64 and ARM) builds and in the following Container Registries:
* `ghcr.io/tob1asdocker/tools:<TAG>`
* `tobi312/tools:<TAG>` [#](https://hub.docker.com/r/tobi312/tools)
* `quay.io/tobi312/tools:<TAG>` [#](https://quay.io/repository/tobi312/tools)

Tools/Tags:
* `figlet`
* `toolbox`
* `pgadmin4`

## figlet 

[FIGlet](http://www.figlet.org/) is a computer program that generates text banners.

### Example
```sh
docker run --rm --name figlet -it tobi312/tools:figlet 'Hello :D'
```
Output:
```sh
 _   _      _ _           ____
| | | | ___| | | ___    _|  _ \
| |_| |/ _ \ | |/ _ \  (_) | | |
|  _  |  __/ | | (_) |  _| |_| |
|_| |_|\___|_|_|\___/  (_)____/

```

## ToolBox

Toolbox with git, wget, curl, nano, netcat and more.

### Example for Docker
```sh
# start
docker run --rm --name toolbox -d tobi312/tools:toolbox
# exec
docker exec -it toolbox sh
# use (example: check port is open)
nc -zv -w 3 <HOST> <PORT>
```

### Example for Kubernetes 
Create file `toolbox.yaml` with this content:
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

## pgAdmin4

[pgAdmin4](https://www.pgadmin.org/) is a Open Source graphical management tool for PostgreSQL.

The Images are [build](https://github.com/Tob1asDocker/tools/blob/main/.github/workflows/build_docker_images-pgadmin4.yaml) from offical [GitHub Repo](https://github.com/postgres/pgadmin4).

For configuration see [https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html)!

### Example for Docker

Create a file `docker-compose.yml` with this content:
```yaml
version: "2.4"
services:
  pgadmin4:
    image: tobi312/tools:pgadmin4
    container_name: pgadmin4
    volumes:
      - ./pgadmin:/var/lib/pgadmin
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@email.local
      - PGADMIN_DEFAULT_PASSWORD=passw0rd
      #- PGADMIN_LISTEN_ADDRESS=0.0.0.0
      - PGADMIN_LISTEN_PORT=5050
      - SCRIPT_NAME=/pgadmin
      # INFO: use PGADMIN_CONFIG_ prefix for any variable name from config.py
      - PGADMIN_CONFIG_LOGIN_BANNER='Multiarch pgAdmin4 :-)'
      - PGADMIN_CONFIG_CONSOLE_LOG_LEVEL=10
    restart: unless-stopped
    ports:
      - 5050:5050
    healthcheck:
      test:  wget --quiet --tries=1 --spider --no-check-certificate http://localhost:5050/pgadmin/misc/ping || exit 1
      start_period: 30s
      interval: 60s
      timeout: 5s
      retries: 5
```

### Example for Kubernetes 

<details>
<summary>Create a file `pgadmin4.yaml` with this content: (click)</summary>
<p>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pgadmin4-env-config
  namespace: default
  labels:
    app: pgadmin4
data:
  #PGADMIN_LISTEN_ADDRESS: "0.0.0.0"
  PGADMIN_LISTEN_PORT: "5050"
  SCRIPT_NAME: "/pgadmin"
  # INFO: use PGADMIN_CONFIG_ prefix for any variable name from config.py
  PGADMIN_CONFIG_LOGIN_BANNER: "\"Multiarch pgAdmin4 :-)\""
  PGADMIN_CONFIG_CONSOLE_LOG_LEVEL: "10"
---
# secret - variable in base64: "echo -n 'value' | base64"
apiVersion: v1
kind: Secret
metadata:
  name: pgadmin4-env-secret
  namespace: default
  labels:
    app: pgadmin4
data:
  PGADMIN_DEFAULT_EMAIL: YWRtaW5AZW1haWwubG9jYWw=  # admin@email.local
  PGADMIN_DEFAULT_PASSWORD: cGFzc3cwcmQ=           # passw0rd
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgadmin4
  namespace: default
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: pgadmin4
  template:
    metadata:
      labels:
        app: pgadmin4
    spec:
      containers:
        - name: pgadmin4
          image: dpage/pgadmin4:latest
          imagePullPolicy: Always
          envFrom:
          - configMapRef:
              name: pgadmin4-env-config
          - secretRef:
              name: pgadmin4-env-secret
          ports:
            - containerPort: 5050
          resources:
            requests:
              memory: "128Mi"
              cpu: "0.1"
            limits:
              memory: "512Mi"
              cpu: "0.5"
          volumeMounts:
            - mountPath: /var/lib/pgadmin
              name: pgadmin-data
      initContainers:
        - name: volume-mount-chmod
          image: busybox
          command: ["sh", "-c", "mkdir -p /var/lib/pgadmin; chmod 777 /var/lib/pgadmin; exit"]
          volumeMounts:
            - mountPath: /var/lib/pgadmin
              name: pgadmin-data
          resources:
            requests:
              memory: "64Mi"
              cpu: "0.1"
            limits:
              memory: "256Mi"
              cpu: "0.5"
      restartPolicy: Always
      volumes:
        - name: pgadmin-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: pgadmin4
  namespace: default
spec:
  ports:
    - name: pgadmin4
      protocol: TCP
      port: 5050
      targetPort: 5050
  selector:
    app: pgadmin4
---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pgadmin4
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    #cert-manager.io/cluster-issuer: ingress-tls-secret
    #cert-manager.io/acme-challenge-type: http01
spec:
  #tls:
  #- hosts:
  #  - tools.example.com
  #  secretName: ingress-tls-secret
  rules:
  - host: tools.example.com
    http:
      paths:
      - path: /pgadmin
        pathType: ImplementationSpecific
        backend:
          service:
            name: pgadmin4
            port:
              #name: pgadmin4
              number: 5050

```

</p>
</details>
