# Central Server Docker Image

The Central Server Docker image contains vanilla X-Road Central Server version 6.20.0 or later.
All services, including TEST-CA, TSA, OCSP and PostgreSQL database, are installed into the same container and run using supervisord.

The installed Central Server is in uninitialized state.

Admin UI credentials: `xrd`/`secret`

## Building and running the Central Server image with remote database

```shell

run.sh -h $db_host -i $db_port -u $db_user -p $db_pass -n $container_name -m $image_name -x $centerui_user_pass
```

