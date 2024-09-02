Postgresql Internals
--------------------

Postgresql docker instance for testing.

```sh
docker run --rm --name postgres_16_4 -p 5432:5432 -e POSTGRES_USER=someuser -e POSTGRES_PASSWORD=somepassword -e POSTGRES_DB="labdb" postgres:16.4
```
