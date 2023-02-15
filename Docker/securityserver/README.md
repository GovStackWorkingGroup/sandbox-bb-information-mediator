# Security Server Docker Image


All services, including the `serverconf` and `messagelog` PostgreSQL databases, are installed into the same container and run using supervisord.
The installed Security Server is in uninitialized state.

Admin UI credentials: `xrd`/`secret`

## Building and running the Security Server image with remote database

```shell

run.sh -h $db_host -i $db_port -u $db_user -p $db_pass -n $container_name -r $serverconf_admin_pass -s $messagelog_admin_pass -t $opmon_admin_pass -v $serverconf_pass -w $messagelog_pass -x $opmon_pass
```
