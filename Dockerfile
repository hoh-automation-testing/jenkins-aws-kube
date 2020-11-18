FROM alpine:3

LABEL maintainer="eXpire163"


# Install apk dependencies
RUN apk --no-cache add \
        bash curl ca-certificates \
        coreutils git gnupg \
        openssl jq openssh-server dos2unix
        

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd


# Add user jenkins to the image
RUN adduser --quiet jenkins
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins" | chpasswd

# RUN mkdir /home/jenkins/.m2

# ADD settings.xml /home/jenkins/.m2/

RUN chown -R jenkins:jenkins /home/jenkins/.m2/ 


# Install Terraform 0.13
ENV TF_VERSION="0.13.3"
ENV TF_BASE_URL="https://releases.hashicorp.com/terraform" \
    TF_FILE_NAME="terraform_${TF_VERSION}_linux_amd64.zip" \
    TF_CHECKSUM_FILE_NAME="terraform_${TF_VERSION}_SHA256SUMS" \
    TF_PLUGIN_CACHE_DIR="/var/cache/terraform"

RUN echo "Downloading Terraform from: ${TF_BASE_URL}/${TF_VERSION}/${TF_FILE_NAME}" \
    && curl -fOL ${TF_BASE_URL}/${TF_VERSION}/${TF_FILE_NAME} \
    && curl -fOL ${TF_BASE_URL}/${TF_VERSION}/${TF_CHECKSUM_FILE_NAME} \
    && curl -fOL ${TF_BASE_URL}/${TF_VERSION}/${TF_CHECKSUM_FILE_NAME}.sig \
    && sha256sum --ignore-missing -c ${TF_CHECKSUM_FILE_NAME} \
    && unzip ${TF_FILE_NAME} -d /tmp \
    && mv /tmp/terraform /usr/bin/terraform0.13 \
    && rm -f ${TF_FILE_NAME} ${TF_CHECKSUM_FILE_NAME}.sig ${TF_CHECKSUM_FILE_NAME} \
    && mkdir -p ${TF_PLUGIN_CACHE_DIR} && chmod 1777 ${TF_PLUGIN_CACHE_DIR} \
    && terraform0.13 --version

# Install kubectl
# find the latest stable version via: curl https://storage.googleapis.com/kubernetes-release/release/stable.txt
ENV KUBECTL_VERSION="v1.19.2" \
    KUBECTL_CHECKSUM="f51adfe7968ee173dbfb3dabfc10dc774983cbf8a3a7c1c75a1423b91fda6821"
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /tmp/kubectl && \
    echo "${KUBECTL_CHECKSUM}  /tmp/kubectl" | sha256sum -c - && \
    mv /tmp/kubectl /usr/bin/kubectl && \
    chmod 0755 /usr/bin/kubectl

# Install AWS cli tool
ENV AWS_CLI_VERSION=1.18.149
RUN apk add --no-cache python3 py3-pip \
    && pip3 --no-cache-dir install \
    awscli==${AWS_CLI_VERSION}

# Install aws-iam-authenticator
ENV AWS_IAM_AUTHENTICATOR_VERSION="1.17.9/2020-08-04" \
    AWS_IAM_AUTHENTICATOR_CHECKSUM="fe958eff955bea1499015b45dc53392a33f737630efd841cd574559cc0f41800"
RUN curl -L https://amazon-eks.s3.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator \
        -o /tmp/aws-iam-authenticator && \
    echo "${AWS_IAM_AUTHENTICATOR_CHECKSUM}  /tmp/aws-iam-authenticator" | sha256sum -c - && \
    mv /tmp/aws-iam-authenticator /usr/bin/aws-iam-authenticator && \
    chmod 0755 /usr/bin/aws-iam-authenticator && \
    aws-iam-authenticator version

# Install amazon-ecr-credential-helper-releases
ENV AMAZON_ECR_CREDENTIAL_HELPER_VERSION="0.4.0" \
    AMAZON_ECR_CREDENTIAL_HELPER_CHECKSUM="2c8fc418fe1b5195388608c1cfb99ba008645f3f1beb312772c9490c39aa5904"
RUN curl -L https://amazon-ecr-credential-helper-releases.s3.amazonaws.com/${AMAZON_ECR_CREDENTIAL_HELPER_VERSION}/linux-amd64/docker-credential-ecr-login \
        -o /tmp/docker-credential-ecr-login && \
    echo "${AMAZON_ECR_CREDENTIAL_HELPER_CHECKSUM}  /tmp/docker-credential-ecr-login" | sha256sum -c - && \
    mv /tmp/docker-credential-ecr-login /usr/bin/docker-credential-ecr-login && \
    chmod 0755 /usr/bin/docker-credential-ecr-login && \
    docker-credential-ecr-login version

# Install helm 3
ENV HELM_VERSION=3.2.3
ENV HELM_BASE_URL="https://get.helm.sh"
ENV HELM_TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

RUN curl -L ${HELM_BASE_URL}/${HELM_TAR_FILE} | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    helm version





# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
