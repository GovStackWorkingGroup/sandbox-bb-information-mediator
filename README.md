# sandbox-information-mediator

Install Helm chart

helm install information-mediator ./information-mediator/

The "information-mediator" chart contains the following sub-charts:

* A chart for X-Road Central Server (information_mediator/charts/xroad-cs)
* A chart for X-Road Security Server with management services (information_mediator/charts/xroad-ssm)
* A chart for consumer X-Road Security Server (information_mediator/charts/xroad-ssc)
* A chart for provider X-Road Security Server (information_mediator/charts/xroad-ssp)

Each chart contains an X-Road component (either Central Server or Security Server), a remote database (ACK RDS) and secrets (passwords created randomly in Kubernetes Cluster)

In addition, there is a "Docker" folder with Dockerfiles and shell scripts for creation of images of X-Road components - when run, there will be created images of X-Road components, 
configured to use remote database instances and those images will be pushed to container registry to be pulled from when installing with Helm charts.

When installing the "information-mediator" chart, the installation of those sub-charts can be configured in the file "./information_mediator/Values.yaml":

- by setting the boolean value of the "enabled" parameter of specific sub-chart
