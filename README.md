# s3fs mount from Docker container

This repository contains a singleton Dockerfile that is capable of mounting s3 bucket
as file system using s3fs fuse.

## Prerequisite
* Make sure you already have an s3 bucket in your AWS account. (The Docker file assume the s3 bucket is in eu-central-1)
* Make sure you have IAM user that allows to perform changes on the S3 bucket
* Create an .env file with security credentials for the IAM user (ACCESS_KEY_ID and SECRET_ACCESS_KEY) - see example.

## Usage
1. export environment variables
```
source .env
```

2. Build the image
```dockerfile
docker build . -t <your_tag_here> --build-arg BUCKET_NAME=<your_s3_bucket_name>
```

3. Run the container
```
podman run -it -e ACCESS_KEY_ID=$ACCESS_KEY_ID -e SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY -d --privileged --device /dev/fuse --cap-add SYS_ADMIN <your_tag_here>
```

4. Check the container is running
```
podman ps
```

5. Attach to the container
```
podman exec -it <your container name> bash
```

6. Check the volume was mounted
```
>df -h
```
You should see something like this:
```
s3fs             64P     0   64P   0% /home/op/s3_bucket
```

## Cleanup
1. Kill running container
```
podman ps -aq | awk '{ print $1}' | xargs podman kill
```
2. Clean built image
```
podman image list | grep <your_tag_here> | awk '{print $3}' | xargs podman image rm -f

