# kt cloud API builder

## To build Swagger Document

```
make openapi
```

## To run Swagger API

```
docker run -p 8080:8080 -e URLS="[{ url: \"./ktcloud/api/identity/user.swagger.json\", name: \"UserManagement\" } ]"  -v $(pwd)/dist/openapi/ktcloud:/usr/share/nginx/html/ktcloud swaggerapi/swagger-ui
```
