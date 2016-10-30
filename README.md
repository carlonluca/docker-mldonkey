# mldonkey docker image

This repository host the Dockerfile for building mldonkey docker image.

## Usage

To run mldonkey using this image:

```
$ docker run -i -t cheungpat/mldonkey
```

You may change the admin password by using the comand `useradd admin <password`,
or you can specify `MLDONKEY_ADMIN_PASSWORD` environment variable with
a password:

```
$ docker run -i -t -e MLDONKEY_ADMIN_PASSWORD=supersecret cheungpat/mldonkey
```

mldonkey stores data inside `/var/lib/mldonkey`. You may want to mount the
data directory to local filesystem. Doing this will persist the data
when you re-create the docker container. It is also easier to get downloaded
files this way.

```
$ docker run -i -t -v "`pwd`/data:/var/lib/mldonkey" cheungpat/mldonkey
```

Your data will be available under `data/incoming` directory where you
run the `docker run` command.

## Notes for Docker for Mac

mldonkey does not like the `temp` directory to reside in Mac filesystem. It is
better to mount `/var/lib/mldonkey/temp` inside the Docker VM filesystem.

The included `docker-compose.yml` set up everything for you. To run in Docker
for Mac,

```
$ docker-compose up
```
