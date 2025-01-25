# Base image with minimal dependencies
FROM python:3.9-slim

# Set environment variables
ENV PROTOC_VERSION=22.3
ENV GRPC_GATEWAY_VERSION=2.26.0
ENV BIN_DIR=/opt/bin
ENV PKG_DIR=/tmp/pkg

COPY pkg/* ${PKG_DIR}/

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade -r ${PKG_DIR}/pip_requirements.txt

# Install protoc
ARG TARGETPLATFORM
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-aarch_64.zip && \
        unzip protoc-${PROTOC_VERSION}-linux-aarch_64.zip -d /usr/local/ && \
        rm protoc-${PROTOC_VERSION}-linux-aarch_64.zip; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
        unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /usr/local/ && \
        rm protoc-${PROTOC_VERSION}-linux-x86_64.zip; \
    fi

# Install grpc-gateway plugins based on architecture
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        curl -L https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-openapiv2-v${GRPC_GATEWAY_VERSION}-linux-arm64 \
        -o /usr/local/bin/protoc-gen-openapiv2 && \
        chmod +x /usr/local/bin/protoc-gen-openapiv2; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        curl -L https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-openapiv2-v${GRPC_GATEWAY_VERSION}-linux-x86_64 \
        -o /usr/local/bin/protoc-gen-openapiv2 && \
        chmod +x /usr/local/bin/protoc-gen-openapiv2; \
    fi

# Set PATH to include /usr/local/bin
ENV PATH=$PATH:/usr/local/bin

# Create a working directory
WORKDIR ${BIN_DIR}

# Add entrypoint for generating documentation
CMD ["python3", "build.py", "-h"]
