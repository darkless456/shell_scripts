# 在 Debian / Ubuntu / Alpine 系统中信任证书

对于 Debian / Ubuntu 系统，信任证书相当简单，只需要将证书拷贝到“待安装目录”，然后执行证书更新命令即可：

```shell
cp *.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

# 在Dockerfile中使用

```dockerfile
FROM alpine

RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

ADD ./ssl/*.crt /usr/local/share/ca-certificates/

RUN update-ca-certificates --fresh
```

# 参考

[如何制作和使用自签名证书](https://soulteary.com/2021/02/06/how-to-make-and-use-a-self-signed-certificate.html#%E5%86%99%E5%9C%A8%E5%89%8D%E9%9D%A2)