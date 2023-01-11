# sandbox-information-mediator

Install Helm chart

helm install information-mediator ./information-mediator/

The "information-mediator" chart contains the following sub-charts:

* xroad-cs
* xroad-ssm
* xroad-ssc
* xroad-ssp

When installing the "information-mediator" chart, the installation of those sub-charts can be configured in the file "./information_mediator/Values.yaml":

- by setting the boolean value of the "enabled" parameter of specific sub-chart
