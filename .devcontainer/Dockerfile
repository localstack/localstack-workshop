FROM debian

RUN sudo apt update

# install node.js
RUN curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
RUN sudo apt -y install nodejs

# install Docker CLI
RUN sudo apt -y install docker.io

# install LocalStack CLI, awslocal, tflocal
RUN pip install localstack awscli-local[ver1] terraform-local

# install CDK utils
RUN sudo chmod 777 /usr/local/lib /usr/local/bin
RUN npm install -g aws-cdk-local aws-cdk
