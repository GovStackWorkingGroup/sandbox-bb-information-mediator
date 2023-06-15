# GovStack Sandbox - Information Mediator (X-Road)

This is a _preconfigured_ setup of X-Road packaged as a Helm application, intended to be deployed into the Govstack Sandbox. The setup should not be exposed to public internet.

The setup consist of the following components:

- Preconfigured Docker images (in `images`) based on NIIS X-Road Central Server and X-Road Security Server Sidecar 7.2.2
    - For more information about X-Road, see http://x-road.global
- Helm Chart (in `sandbox-im-x-road`) for deploying the application to a Kubernetes cluster

The application has the following components:

- X-Road Central Server (sandbox-xroad-cs)
    - X-Road instance id: SANDBOX
    - The Central Server includes a simple Test CA running in port 8888/HTTP
- Three X-Road Security Servers
    - sandbox-xroad-ss1 - management server
        - server id: SANDBOX/GOV/MANAGEMENT/SS1
    - sandbox-xroad-ss2 - consumer server
        - server id: SANDBOX/ORG/CLIENT/SS2
    - sandbox-xroad-ss3 - provider server
        - server  id: SANDBOX/GOV/PROVIDER/SS3
- Preconfigured subsystems:
    - SANDBOX/GOV/MGMT/MANAGEMENT (registered on SS1)
        - for management services
    - SANDBOX/ORG/CLIENT/TEST (registered on SS2)
    - SANDBOX/GOV/PROVIDER/TEST (registered on SS3)

Admin interfaces have and admin user with username `xrd` and password `secret`. Software token pin code is `1234` in the packaged configuration.

## Quickstart

Build preconfigured images and push them to a registry that can be accessed by the Sandbox. The build script creates several images and pushes those to 
`<registry base url>/im/x-road/(securty-server|central-server)`

```
images/docker-build.sh -r <registry base url> -p
```

Install the chart to a Sandbox. The chart assumes that the cluster supports dynamic volume provisioning with sensible defaults. If that is not the case, the various volumes need to be manually provisioned.

```
helm install --atomic \
    --wait --timeout 15m \
    --create-namespace \
    --namespace "sandbox-im" \
    --set-string xroad-ss.tokenPin="1234" \
    --set-string xroad-cs.tokenPin="1234" \
    --set-string global.registry="<registry base url>" \
    sandbox-im-xroad ./x-road/sandbox-im-x-road
```

After the install finishes, one can access the interfaces e.g. with port forwarding. 
```
kubectl port-forward \
    -n sandbox-im \
    service/sandbox-xroad-ss2 4000 8443
```

There is also a pre-defined test service which can be used to check that the deployment was succesful. Assuming the previous port-forward:
```
curl --fail-with-body -k \
    -HX-Road-Client:SANDBOX/ORG/CLIENT/TEST \
    https:/localhost:8443/r1/SANDBOX/GOV/PROVIDER/TEST/health/
```
