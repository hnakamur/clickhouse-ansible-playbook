# clickhouse-ansible-playbook

* An Ansible playbook to set up a ClickHouse cluster.
* Ubuntu 24.04

## How to set up

* Create a project and containers on [Incus](https://linuxcontainers.org/incus/).

```
./create_incus_containers.sh clickhouse
```

* Run the playbook using [uv](https://docs.astral.sh/uv/).

```
uv run ansible-playbook playbook.yml
```

## References

* https://clickhouse.com/docs/en/install#install-from-deb-packages
* [Replication for fault tolerance | ClickHouse Docs](https://clickhouse.com/docs/en/architecture/replication)
