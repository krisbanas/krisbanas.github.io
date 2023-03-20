# Chaotic Notes

My personal blog hosting a collection of nature's intricacies.

## Development

First, **create the development image**. Run the command in the root of the repository:

```shell
docker build . -t ruby-builder
```

Run the container attached to the local system and start the server

```shell
docker run -it --rm -v ${pwd}:/application -p 4000:4000 ruby-builder
```
