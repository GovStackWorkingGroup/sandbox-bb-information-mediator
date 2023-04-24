# sandbox-information-mediator

The Sandbox Information Mediator(IM) BB is implemented by [X-Road](https://github.com/nordic-institute/X-Road)

# Introduction

The Sandbox Information Mediator(IM) BB in implemented by running [X-Road Central Server](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ig-cs_x-road_6_central_server_installation_guide.md) and [X-Road Security Server](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ig-ss_x-road_v6_security_server_installation_guide.md) in Kubernetes Cluster in the cloud. The initial goal is to implement it in as much cloud agnostic way as possible. 

# Tooling

  The tools used for building and deploying the IM to Kubernetes Cluster in the cloud:

  * [Helm charts](https://helm.sh/docs/topics/charts/)
  * [Docker](https://www.docker.com/) for X-Road containerization
  * [CircleCI](https://circleci.com/) for CI/CD

# Process

1. Running X-Road Central Server in a Docker container
   
   ``` $ docker run -d -p 4000:4000 -p 4001:80 -p 4002:9998 --name cs <XROAD_CENTRAL_SERVER_IMAGE> ```

   * XROAD_CENTRAL_SERVER_IMAGE - [official NIIS X-Road Central Server Dockerhub image](https://hub.docker.com/r/niis/xroad-central-server)

2. Running X-Road Security Servers in Docker containers
   
   ``` $ docker run -d -p 4100:4000 -p 8081:8080 --name ssm -e XROAD_TOKEN_PIN=<XROAD_TOKEN_PIN> <XROAD_SECURITY_SERVER_IMAGE> ```
   ``` $ docker run -d -p 4200:4000 -p 8082:8080 --name ssc -e XROAD_TOKEN_PIN=<XROAD_TOKEN_PIN> <XROAD_SECURITY_SERVER_IMAGE> ```
   ``` $ docker run -d -p 4300:4000 -p 8083:8080 --name ssp -e XROAD_TOKEN_PIN=<XROAD_TOKEN_PIN> <XROAD_SECURITY_SERVER_IMAGE> ```

   * XROAD_TOKEN_PIN - X-Road pin token, e.g. 1234
   * XROAD_SECURITY_SERVER_IMAGE - [official NIIS X-Road Security Server Dockerhub image](https://hub.docker.com/r/niis/xroad-security-server)

3. Substituting Docker entrypoint.sh script in docker containers with a custom entrypoint.sh script
 
   for the Central Server container:
   ``` $ docker cp information-mediator/scripts/central-server-entrypoint.sh <CID>:/root/entrypoint.sh ```

   and for the Security Server container (the same has to be done for each Security Server container if there are multiple):
   ``` $ docker cp information-mediator/scripts/security-server-entrypoint.sh <CID>/root/entrypoint.sh ```
   
   * CID - docker container id (can be obtained by for example by ``` $ export CID=$(docker ps -aqf "name=cs") ``` where the  ```name``` is the container name

   **NOTE** 
   The [central-server-entrypoint.sh](information-mediator/scripts/central-server-entrypoint.sh) and [security-server-entrypoint.sh](information-mediator/scripts/security-server-entrypoint.sh) scripts contain customizations to the original Docker entrypoint.sh script to configure the X-Road components to use remote database
   instead of local database that is the default option for X-Road and also to create SQL scripts for data migration from local to remote database. The custom entrypoint script
   will be run the next time the Docker container is run and some required parameter values will be provided by environment variables.

4. Restoring configuration from backups (if those exist, if not process to step 5)

   for the Central Server:
   ``` $ docker cp conf_backup.tar <CID>:/var/lib/xroad/backup/conf_backup.tar ```
   ``` $ docker exec -it --user xroad <CID> bin/bash -c '/usr/share/xroad/scripts/restore_xroad_center_configuration.sh -i <XROAD_INSTANCE> -f /var/lib/xroad/backup/conf_backup.tar' ```

   for the Security Server:
   ``` $ docker cp conf_backup.tar <CID>:/var/lib/xroad/backup/conf_backup.tar ```
   ``` $ docker exec -it --user xroad <CID> bin/bash -c '/usr/share/xroad/scripts/restore_xroad_proxy_configuration.sh -F -P -f /var/lib/xroad/backup/conf_backup.tar ```   

   * CID - docker container id (can be obtained by for example by ``` $ export CID=$(docker ps -aqf "name=cs") ``` where the  ```name``` is the container name
   * XROAD_INSTANCE - X-Road instance name, e.g. DEV
   * XROAD_SS_ID - X-Road Security Server identificator, e.g. DEV/GOV/1234/SS1

   **NOTE**
   There is more information related to backups of X-Road components [here](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ug-cs_x-road_6_central_server_user_guide.md#133-restoring-the-configuration-from-the-command-line) and [here](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md#132-restore-from-the-command-line). 

5. Manual configuration of X-Road components (Skip, if already configured or configuration restored in step 4)

   For configuring the Central Server please refer to [X-Road Central Server UG](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ug-cs_x-road_6_central_server_user_guide.md)
   
   For configuring the Security Server please refer to [X-Road Security Server UG](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md)


6. Creation of pre-configured images from the Docker containers and push/deployment to some repository
 
   For committing the container to an image
   ``` $ docker commit <CID> <IMAGE_NAME> ```

   For connecting Docker to a container repository in the cloud e.g. AWS ECR
   ``` $ aws ecr get-login-password --region <AWS_REGION> --profile <AWS_PROFILE> | docker login --username AWS --password-stdin <AWS_ECR_URL> ```

   For tagging the Docker image
   ``` $ docker tag <IMAGE_NAME>:latest <AWS_ECR_REPO>:<IMAGE_NAME> ```

   For pushing the pre-configured Docker image to container repository e.g. AWS ECR
   ``` $ docker push <AWS_ECR_REPO>:<IMAGE_NAME> ```

   * CID - docker container id (can be obtained by for example by ``` $ export CID=$(docker ps -aqf "name=cs") ``` where the  ```name``` is the container name)
   * IMAGE_NAME - the name of the docker image, e.g. xroad-cs
   * AWS_REGION - the region in the cloud, where the repository is located e.g. eu-west-1
   * AWS_PROFILE - the AWS identification profile used for connection e.g. govstack-sandbox
   * AWS_ECR_URL - the URL for the AWS ECR e.g. 123456789.dkr.ecr.eu-west-1.amazonaws.com
   * AWS_ECR_REPO - the repository URL in AWS ECR, e.g 123456789.dkr.ecr.eu-west-1.amazonaws.com/im/x-road

7. Install secrets (passwords) to the Kubernetes Cluster with Helm charts

   First, some environment variables need to be set:
   * NAMESPACE - the name of the namespace to which the IM will be intalled in the Kubernetes Cluster
   * XROAD_CS_ENABLED - boolean value indicating whether X-Road Central Server should be installed or not
   * XROAD_SSC_ENABLED - boolean value indicating whether X-Road consumer Security Server should be installed or not
   * XROAD_SSM_ENABLED - boolean value indicating whether X-Road Securty Server with management services should be installed or not
   * XROAD_SSP_ENABLED - boolean value indicating whether X-Road provider Security Server should be installed or not
   * SECRETS_ENABLED - boolean value indicating if secrets (passwords) should be generated in the Kubernetes Cluster or not (recommended value is ```true``` in this step)
   * POSTGRES_ENABLED - boolean value indicating if PostgreSQL database should be installed to the Kubernetes Cluster or not (recommended value is ```false``` in this step)
   * APPLICATION_ENABLED - boolean value indicating if the IM should be installed to the Kubernetes Cluster or not (recommended value is ```false``` in this step)
   
   Next, the ```values.yaml``` file is copied to a temporary values file:
   ``` $ cp ./information-mediator/values.yaml val.yaml ```
   
   Now, the placeholders for those environment variables in the temporary values file will be substituted with real values taken from those environment variables set previously:
   ``` $ sed -i 's/${NAMESPACE}/'"$NAMESPACE"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_CS_ENABLED}/'"$XROAD_CS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSC_ENABLED}/'"$XROAD_SSC_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSM_ENABLED}/'"$XROAD_SSM_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSP_ENABLED}/'"$XROAD_SSP_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${POSTGRES_ENABLED}/'"$POSTGRES_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${SECRETS_ENABLED}/'"$SECRETS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${APPLICATION_ENABLED}/'"$APPLICATION_ENABLED"'/g' val.yaml ```
   
   Finally, that temporary values file is used to install secrets (passwords) to Kubernetes Cluster:
   ``` $ helm upgrade --install information-mediator ./information-mediator/ -f val.yaml ```

8. Install PostgreSQL database to the Kubernetes Cluster with Helm charts

   First, some environment variables need to be set:
   * NAMESPACE - the name of the namespace to which the IM will be intalled in the Kubernetes Cluster
   * XROAD_CS_ENABLED - boolean value indicating whether X-Road Central Server should be installed or not
   * XROAD_SSC_ENABLED - boolean value indicating whether X-Road consumer Security Server should be installed or not
   * XROAD_SSM_ENABLED - boolean value indicating whether X-Road Securty Server with management services should be installed or not
   * XROAD_SSP_ENABLED - boolean value indicating whether X-Road provider Security Server should be installed or not
   * PGDATA - folder to keep PostgreSQL database data in, e.g. "/var/lib/postgresql/data"
   * POSTGRES_USER - admin user's name for PostgreSQL database, e.g. "postgres"
   * XROAD_TOKEN_PIN - X-Road pin token, e.g. "1234"
   * SECRETS_ENABLED - boolean value indicating if secrets (passwords) should be generated in the Kubernetes Cluster or not (recommended value is ```false``` in this step)
   * POSTGRES_ENABLED - boolean value indicating if PostgreSQL database should be installed to the Kubernetes Cluster or not (recommended value is ```true``` in this step)
   * APPLICATION_ENABLED - boolean value indicating if the IM should be installed to the Kubernetes Cluster or not (recommended value is ```false``` in this step)   

   Next, the ```values.yaml``` file is copied to a temporary values file:
   ``` $ cp ./information-mediator/values.yaml val.yaml ```

   Now, the placeholders for those environment variables in the temporary values file will be substituted with real values taken from those environment variables set previously:
   ``` $ sed -i 's/${NAMESPACE}/'"$NAMESPACE"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_CS_ENABLED}/'"$XROAD_CS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSC_ENABLED}/'"$XROAD_SSC_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSM_ENABLED}/'"$XROAD_SSM_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSP_ENABLED}/'"$XROAD_SSP_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${PGDATA}/'"$PGDATA"'/g' val.yaml ```
   ``` $ sed -i 's/${POSTGRES_USER}/'"$POSTGRES_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_TOKEN_PIN}/'"$XROAD_TOKEN_PIN"'/g' val.yaml ```
   ``` $ sed -i 's/${POSTGRES_ENABLED}/'"$POSTGRES_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${SECRETS_ENABLED}/'"$SECRETS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${APPLICATION_ENABLED}/'"$APPLICATION_ENABLED"'/g' val.yaml ```

   Finally, that temporary values file is used to install PostgreSQL database to Kubernetes Cluster:
   ``` $ helm upgrade --install information-mediator ./information-mediator/ -f val.yaml ```

9. Configure the PostgreSQL database in the Kubernetes Cluster with Helm charts

   First, some environment variables need to be set:
   * NAMESPACE - the name of the namespace to which the IM will be intalled in the Kubernetes Cluster
   * POSTGRES_USER - admin user's name for PostgreSQL database, e.g. "postgres"
   * CS_PASS - Central Server's PostgreSQL database admin password taken from stored secret(password) in Kubernetes Cluster, e.g.
     ``` $ $(kubectl get secret govstack-xroad-cs-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_PASS - consumer Security Server's PostgreSQL database admin password taken from stored secret(password) in Kubernetes Cluster, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSM_PASS - Security Server with management services PostgreSQL database admin password taken from stored secret(password) in Kubernetes Cluster, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSP_PASS - provider Security Server's PostgreSQL database admin password taken from stored secret(password) in Kubernetes Cluster, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```

   Finally, set admin password for PostgreSQL databases:
   ``` $ kubectl exec -it service/govstack-xroad-cs-postgres -n $NAMESPACE -- psql -h localhost -U $POSTGRES_USER -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${CS_PASS}'" ```
   ``` $ kubectl exec -it service/govstack-xroad-ssc-postgres -n $NAMESPACE -- psql -h localhost -U $POSTGRES_USER -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${SSC_PASS}'" ```
   ``` $ kubectl exec -it service/govstack-xroad-ssm-postgres -n $NAMESPACE -- psql -h localhost -U $POSTGRES_USER -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${SSM_PASS}'" ```
   ``` $ kubectl exec -it service/govstack-xroad-ssp-postgres -n $NAMESPACE -- psql -h localhost -U $POSTGRES_USER -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${SSP_PASS}'"  ```

10. Install X-Road components to the Kubernetes Cluster with Helm charts

   First, some environment variables need to be set:
   * NAMESPACE - the name of the namespace to which the IM will be intalled in the Kubernetes Cluster
   * XROAD_CS_ENABLED - boolean value indicating whether X-Road Central Server should be installed or not
   * XROAD_SSC_ENABLED - boolean value indicating whether X-Road consumer Security Server should be installed or not
   * XROAD_SSM_ENABLED - boolean value indicating whether X-Road Securty Server with management services should be installed or not
   * XROAD_SSP_ENABLED - boolean value indicating whether X-Road provider Security Server should be installed or not
   * PGDATA - folder to keep PostgreSQL database data in, e.g. "/var/lib/postgresql/data"
   * POSTGRES_USER - admin user's name for PostgreSQL database, e.g. "postgres"
   * XROAD_TOKEN_PIN - X-Road pin token, e.g. "1234"
   * SECRETS_ENABLED - boolean value indicating if secrets (passwords) should be generated in the Kubernetes Cluster or not (recommended value is ```false``` in this step)
   * POSTGRES_ENABLED - boolean value indicating if PostgreSQL database should be installed to the Kubernetes Cluster or not (recommended value is ```true``` in this step)
   * APPLICATION_ENABLED - boolean value indicating if the IM should be installed to the Kubernetes Cluster or not (recommended value is ```true``` in this step) 
   * ECR_CS_REPO - Central Server container registry repository name, e.g. 123456789.dkr.ecr.eu-west-1.amazonaws.com\/im\/x-road\/central-server (note: slashes have to be escaped)
   * ECR_SS_REPO - Security Server container registry repository name, e.g. 123456789.dkr.ecr.eu-west-1.amazonaws.com\/im\/x-road\/security-server (note: slashes have to be escaped)
   * ECR_CS_IMAGE_NAME - Central Server image name, e.g. im-xroad-cs
   * ECR_SSM_IMAGE_NAME - Security Server with management services image name, e.g. im-xroad-ssm
   * ECR_SSC_IMAGE_NAME - consumer Security Server image name, e.g. im-xroad-ssc
   * ECR_SSP_IMAGE_NAME- provider Security Server image name, e.g. im-xroad-ssp
   * CS_DB_HOST - PostgreSQL database host for Central Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-cs-postgres -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE) ```
   * CS_DB_PORT - PostgreSQL database port for Central Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-cs-postgres -o jsonpath='{.spec.ports[0].port}' -n $NAMESPACE) ```
   * CS_DB_ADMIN_USER - PostgreSQL database admin user for Central Server, e.g. "postgres"
   * CS_DB_ADMIN_PASS - PostgresSQL database admin password for Central Server, e.g.:
     ``` $ $(kubectl get secret govstack-xroad-cs-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * CS_DB_UI_PASS - PostgreSQL database password for "centerui" db user for Central Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-cs-postgres-centerui-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_DB_HOST - PostgreSQL database host for consumer Security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssc-postgres -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE) ```
   * SSC_DB_PORT - PostgreSQL database port for consumer security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssc-postgres -o jsonpath='{.spec.ports[0].port}' -n $NAMESPACE) ```            
   * SSC_DB_ADMIN_USER - PostgreSQL database admin user for consumer Security Server, e.g. "postgres"
   * SSC_DB_ADMIN_PASS - PostgreSQL database admin password for consumer Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_DB_SERVERCONF_ADMIN_PASS - PostgreSQL database password for "serverconf-admin" user for consumer Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-serverconf-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_DB_MESSAGELOG_ADMIN_PASS - PostgreSQL database password for "messagelog-admin" user for consumer Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-messagelog-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_DB_SERVERCONF_PASS - PostgreSQL database password for "serverconf" user for consumer Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-serverconf-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSC_DB_MESSAGELOG_PASS - PostgreSQL database password for "messagelog" user for consumer Security Server, e.g. 
     ``` $ $(kubectl get secret govstack-xroad-ssc-postgres-messagelog-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```               
   * SSM_DB_HOST - PostgreSQL database host for management services Security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssm-postgres -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE) ```
   * SSM_DB_PORT - PostgreSQL database port for management services security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssm-postgres -o jsonpath='{.spec.ports[0].port}' -n $NAMESPACE) ```            
   * SSM_DB_ADMIN_USER - PostgreSQL database admin user for management services Security Server, e.g. "postgres"
   * SSM_DB_ADMIN_PASS - PostgreSQL database admin password for management services Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSM_DB_SERVERCONF_ADMIN_PASS - PostgreSQL database password for "serverconf-admin" user for management services Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-serverconf-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSM_DB_MESSAGELOG_ADMIN_PASS - PostgreSQL database password for "messagelog-admin" user for management services Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-messagelog-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSM_DB_SERVERCONF_PASS - PostgreSQL database password for "serverconf" user for management services Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-serverconf-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSm_DB_MESSAGELOG_PASS - PostgreSQL database password for "messagelog" user for management services Security Server, e.g. 
     ``` $ $(kubectl get secret govstack-xroad-ssm-postgres-messagelog-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSP_DB_HOST - PostgreSQL database host for provider Security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssp-postgres -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE) ```
   * SSP_DB_PORT - PostgreSQL database port for provider security Server, e.g.
     ``` $ $(kubectl get service govstack-xroad-ssp-postgres -o jsonpath='{.spec.ports[0].port}' -n $NAMESPACE) ```            
   * SSP_DB_ADMIN_USER - PostgreSQL database admin user for provider Security Server, e.g. "postgres"
   * SSp_DB_ADMIN_PASS - PostgreSQL database admin password for provider Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSP_DB_SERVERCONF_ADMIN_PASS - PostgreSQL database password for "serverconf-admin" user for provider Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-serverconf-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSp_DB_MESSAGELOG_ADMIN_PASS - PostgreSQL database password for "messagelog-admin" user for provider Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-messagelog-admin-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSp_DB_SERVERCONF_PASS - PostgreSQL database password for "serverconf" user for provider Security Server, e.g.
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-serverconf-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```
   * SSP_DB_MESSAGELOG_PASS - PostgreSQL database password for "messagelog" user for provider Security Server, e.g. 
     ``` $ $(kubectl get secret govstack-xroad-ssp-postgres-messagelog-secret -o jsonpath='{.data.password}' --namespace $NAMESPACE | base64 --decode) ```  

   Next, the ```values.yaml``` file is copied to a temporary values file:
   ``` $ cp ./information-mediator/values.yaml val.yaml ```

   Now, the placeholders for those environment variables in the temporary values file will be substituted with real values taken from those environment variables set previously:
   ``` $ sed -i 's/${NAMESPACE}/'"$NAMESPACE"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_CS_ENABLED}/'"$XROAD_CS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSC_ENABLED}/'"$XROAD_SSC_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSM_ENABLED}/'"$XROAD_SSM_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_SSP_ENABLED}/'"$XROAD_SSP_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${PGDATA}/'"$PGDATA"'/g' val.yaml ```
   ``` $ sed -i 's/${POSTGRES_USER}/'"$POSTGRES_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${XROAD_TOKEN_PIN}/'"$XROAD_TOKEN_PIN"'/g' val.yaml ```
   ``` $ sed -i 's/${POSTGRES_ENABLED}/'"$POSTGRES_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${SECRETS_ENABLED}/'"$SECRETS_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${APPLICATION_ENABLED}/'"$APPLICATION_ENABLED"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_CS_REPO}/'"$ECR_CS_REPO"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_SS_REPO}/'"$ECR_SS_REPO"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_CS_IMAGE_NAME}/'"$ECR_CS_IMAGE_NAME"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_SSM_IMAGE_NAME}/'"$ECR_SSM_IMAGE_NAME"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_SSC_IMAGE_NAME}/'"$ECR_SSC_IMAGE_NAME"'/g' val.yaml ```
   ``` $ sed -i 's/${ECR_SSP_IMAGE_NAME}/'"$ECR_SSP_IMAGE_NAME"'/g' val.yaml ```
   ``` $ sed -i 's/${CS_DB_HOST}/'"$CS_DB_HOST"'/g' val.yaml ```
   ``` $ sed -i 's/${CS_DB_PORT}/'"$CS_DB_PORT"'/g' val.yaml ```
   ``` $ sed -i 's/${CS_DB_ADMIN_USER}/'"$CS_DB_ADMIN_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${CS_DB_ADMIN_PASS}/'"$CS_DB_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${CS_DB_UI_PASS}/'"$CS_DB_UI_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_HOST}/'"$SSC_DB_HOST"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_PORT}/'"$SSC_DB_PORT"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_ADMIN_USER}/'"$SSC_DB_ADMIN_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_ADMIN_PASS}/'"$SSC_DB_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_SERVERCONF_ADMIN_PASS}/'"$SSC_DB_SERVERCONF_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_MESSAGELOG_ADMIN_PASS}/'"$SSC_DB_MESSAGELOG_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_SERVERCONF_PASS}/'"$SSC_DB_SERVERCONF_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSC_DB_MESSAGELOG_PASS}/'"$SSC_DB_MESSAGELOG_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_HOST}/'"$SSM_DB_HOST"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_PORT}/'"$SSM_DB_PORT"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_ADMIN_USER}/'"$SSM_DB_ADMIN_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_ADMIN_PASS}/'"$SSM_DB_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_SERVERCONF_ADMIN_PASS}/'"$SSM_DB_SERVERCONF_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_MESSAGELOG_ADMIN_PASS}/'"$SSM_DB_MESSAGELOG_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_SERVERCONF_PASS}/'"$SSM_DB_SERVERCONF_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSM_DB_MESSAGELOG_PASS}/'"$SSM_DB_MESSAGELOG_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_HOST}/'"$SSP_DB_HOST"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_PORT}/'"$SSP_DB_PORT"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_ADMIN_USER}/'"$SSP_DB_ADMIN_USER"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_ADMIN_PASS}/'"$SSP_DB_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_SERVERCONF_ADMIN_PASS}/'"$SSP_DB_SERVERCONF_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_MESSAGELOG_ADMIN_PASS}/'"$SSP_DB_MESSAGELOG_ADMIN_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_SERVERCONF_PASS}/'"$SSP_DB_SERVERCONF_PASS"'/g' val.yaml ```
   ``` $ sed -i 's/${SSP_DB_MESSAGELOG_PASS}/'"$SSP_DB_MESSAGELOG_PASS"'/g' val.yaml ```

   Finally, that temporary values file is used to install IM to Kubernetes Cluster:
   ``` $ helm upgrade --install information-mediator ./information-mediator/ -f val.yaml ```

11. Structure of Helm charts

   The "information-mediator" chart contains the following sub-charts:

   * A chart for [X-Road Central Server](information_mediator/charts/xroad-cs)
     the sub-chart contains also the following templates:
     - [application.yaml](information_mediator/charts/xroad-cs/templates/application.yaml) for installing X-Road Central Server pod and service to Kubernetes Cluster
     - [postgres.yaml](information_mediator/charts/xroad-cs/templates/postgres.yaml) for installing X-Road Central Server PostgresSQL database to Kubernetes Cluster
     - [secret.yaml](information_mediator/charts/xroad-cs/templates/secret.yaml) for installing X-Road Central Server secrets to Kubernetes Cluster
   * A chart for [X-Road management services Security Server](information_mediator/charts/xroad-ssm)
     the sub-chart contains also the following templates:
     - [application.yaml](information_mediator/charts/xroad-ssm/templates/application.yaml) for installing X-Road management services Security Server pod and service to Kubernetes Cluster
     - [postgres.yaml](information_mediator/charts/xroad-ssm/templates/postgres.yaml) for installing X-Road management services Security Server PostgresSQL database to Kubernetes Cluster
     - [secret.yaml](information_mediator/charts/xroad-ssm/templates/secret.yaml) for installing X-Road management services Security Server secrets to Kubernetes Cluster
   * A chart for [X-Road consumer Security Server](information_mediator/charts/xroad-ssc)
     the sub-chart contains also the following templates:
     - [application.yaml](information_mediator/charts/xroad-ssc/templates/application.yaml) for installing X-Road consumer Security Server pod and service to Kubernetes Cluster
     - [postgres.yaml](information_mediator/charts/xroad-ssc/templates/postgres.yaml) for installing X-Road consumer Security Server PostgresSQL database to Kubernetes Cluster
     - [secret.yaml](information_mediator/charts/xroad-ssc/templates/secret.yaml) for installing X-Road comnsumer Security Server secrets to Kubernetes Cluster
   * A chart for [X-Road provider Security Server](information_mediator/charts/xroad-ssp)
     the sub-chart contains also the following templates:
     - [application.yaml](information_mediator/charts/xroad-ssp/templates/application.yaml) for installing X-Road provider Security Server pod and service to Kubernetes Cluster
     - [postgres.yaml](information_mediator/charts/xroad-ssp/templates/postgres.yaml) for installing X-Road provider Security Server PostgresSQL database to Kubernetes Cluster
     - [secret.yaml](information_mediator/charts/xroad-ssp/templates/secret.yaml) for installing X-Road provider Security Server secrets to Kubernetes Cluster     
   
12. CI / CD pipeline

   There is also a [CircleCI pipeline](.circleci/config.yml) created for automation of those previous steps.

   The pipeline uses the following environment variables (which can be set under configuration of the CircleCI project):
   
   * AWS_CLUSTER_NAME - Kubernetes cluster name, e.g. "Govstack-sandbox"
   * AWS_ROLE - user role used in the cloud for accessing the cluster and its resources, e.g. "sandbox-bb-information-mediator_dev"
   * AWS_DEFAULT_REGION - default region of the cluster, e.g. "eu-west-1"
   * AWS_NAMESPACE - namespace name, where the cluster resides in the cloud, e.g. "govstack"
   * AWS_ACCOUNT - identity account name for accessing the cluster and its resources e.g. "123456789"
   * AWS_IM_S3_BUCKET - S3 bucket for storing configuration backups of X-Road, e.g. "govstack-sandbox"
   * AWS_IM_S3_BUCKET_CS_FOLDER - folder in the S3 bucket for storing Central Server configuraton backups, e.g. "x-road/central-server"
   * AWS_IM_S3_BUCKET_SS_FOLDER - folder in the S3 bucket for storing Security Server configuration backups, "x-road/security-server"
   * AWS_IM_S3_BUCKET_CS_BACKUP_FILE - Central Server configuration backup file name, e.g. "conf_backup.tar"
   * AWS_IM_S3_BUCKET_SSM_BACKUP_FILE - management services Security Server configuration backup file name, e.g. "conf_backup_ssm.tar"
   * AWS_IM_S3_BUCKET_SSC_BACKUP_FILE - consumer Security Server configuration backup file name, e.g. "conf_backup_ssc.tar"
   * AWS_IM_S3_BUCKET_SSP_BACKUP_FILE - provider Security Server configuration backup file name, e.g. "conf_backup_ssp.tar"
   * AWS_ECR_REPO_IM_PREFIX - repository prefix for the IM container registry, e.g. "im"
   * AWS_ECR_REPO_XROAD_PREFIX - repository prefix for X-Road in the container registry, e.g. "x-road"  
   * AWS_ECR_CS_REPO_NAME - name for the container registry of the Central Server, e.g. "central-server"
   * AWS_ECR_SS_REPO_NAME - name for the container registry of the Security Server, e.g. "security-server"
   * IM_XROAD_GENERATE_NEW_SECRETS - boolean value indicating whether secrets (passwords) should be generated for the X-Road components in the cluster
   * IM_XROAD_PGDATA - folder to keep PostgreSQL database data in, e.g. "/var/lib/postgresql/data"
   * IM_XROAD_POSTGRES_USER - admin user's name for PostgreSQL database, e.g. "postgres"
   * IM_XROAD_CS_ENABLED - boolean value indicating whether X-Road Central Server should be installed or not
   * IM_XROAD_SSM_ENABLED - boolean value indicating whether X-Road management services Security Server should be installed or not
   * IM_XROAD_SSC_ENABLED - boolean value indicating whether X-Road consumer Security Server should be installed or not
   * IM_XROAD_SSP_ENABLED - boolean value indicating whether X-Road provider Security Server should be installed or not
   * IM_XROAD_INSTANCE - X-Road instance used in the X-Road servers, e.g. "DEV"
   * IM_XROAD_CS_IMAGE_NAME - X-Road Central Server image name used in the container registry, e.g. "im-xroad-cs" 
   * IM_XROAD_SSM_IMAGE_NAME - X-Road management services Security Server image name used in the container registry, e.g. "im-xroad-ssm"
   * IM_XROAD_SSC_IMAGE_NAME - X-Road consumer Security Server image name used in the container registry, e.g. "im-xroad-ssc"
   * IM_XROAD_SSP_IMAGE_NAME - X-Road provider Security Server image name used in the container registry, e.g. "im-xroad-ssp"
   * IM_XROAD_CENTRAL_SERVER_DOCKERHUB_IMAGE - X-Road Central Server image name in official NIIS Dockerhub, e.g. "niis/xroad-central-server:latest"
   * IM_XROAD_SECURITY_SERVER_DOCKERHUB_IMAGE - X-Road Security Server image name in official NIIS Dockerhub, e.g. "niis/xroad-security-server:latest"
   * IM_XROAD_TOKEN_PIN - X-Road pin token, e.g. "1234"
   * IM_XROAD_CREATE_CS_IMAGE - boolean value indicating whether X-Road Central Server image should be re-created, pre-configured and pushed to the container registry
   * IM_XROAD_CREATE_SSM_IMAGE - boolean value indicating whether X-Road management services Security Server image should be re-created, pre-configured and pushed to the container registry
   * IM_XROAD_CREATE_SSC_IMAGE - boolean value indicating whether X-Road consumer Security Server image should be re-created, pre-configured and pushed to the container registry
   * IM_XROAD_CREATE_SSP_IMAGE - boolean value indicating whether X-Road provider Security Server image should be re-created, pre-configured and pushed to the container registry
   * IM_XROAD_DEPLOY_TO_CLUSTER - boolean value indicating whether Information Mediator should be deployed to the Kubernetes Cluster
