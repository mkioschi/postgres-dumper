# Postgres Dumper


## For Decrypt
Sintax:
```sh
$ openssl enc -d -aes-256-cbc -in <encrypted_file> -out <decrypted_file> -k <password>
```

Example
```sh
$ openssl enc -d -aes-256-cbc -in dump_datetime.sql.gz.enc -out dump_datetime.sql.gz -k 123456
```

Restore
```sh
cat dump_datetime.sql | docker exec -i <container_name> psql postgresql://<username>:<password>@<container_name>/<database>
```