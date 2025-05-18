#!/bin/bash
aws ecr get-login-password --region il-central-1 | docker login --username AWS --password-stdin 314525640319.dkr.ecr.il-central-1.amazonaws.com
docker build -t dor/filebeat .
docker tag dor/filebeat:latest 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/filebeat:latest
docker push 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/filebeat:latest
