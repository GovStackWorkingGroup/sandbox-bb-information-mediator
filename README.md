# sandbox-information-mediator

Install Helm chart

helm install information-mediator ./information-mediator/

The "information-mediator" chart contains the following sub-charts:

* A chart for X-Road Central Server (information_mediator/charts/xroad-cs)
* A chart for X-Road Security Server with management services (information_mediator/charts/xroad-ssm)
* A chart for consumer X-Road Security Server (information_mediator/charts/xroad-ssc)
* A chart for provider X-Road Security Server (information_mediator/charts/xroad-ssp)

When installing the "information-mediator" chart, the installation of those sub-charts can be configured in the file "./information_mediator/Values.yaml":

- by setting the boolean value of the "enabled" parameter of specific sub-chart
