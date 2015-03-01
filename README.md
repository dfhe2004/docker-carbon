To build:

```
docker build -t dfhe2004/docker-carbon .
```

To run:

```
docker run -d \
           -p 8125:8125/udp -p 8126:8126\
           -v /opt/graphite \
           --name carbon dfhe2004/carbon
```
