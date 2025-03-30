FROM python:3.13-slim-bookworm

# Install dependencies
RUN apt update && apt install curl tar git jq procps nginx parallel -y
RUN curl https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.15.6-19d2b4c8.tar.gz -o geth.tar.gz && \
  tar xf geth.tar.gz && \
  mkdir /root/geth && \
  mv geth-linux-amd64-1.15.6-19d2b4c8/geth /root/geth/geth && \
  rm -rf geth.tar.gz geth-linux-amd64-1.15.6-19d2b4c8
RUN curl -sSfL https://release.anza.xyz/v2.1.16/install | bash
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="$PATH:/root/geth:/root/.local/share/solana/install/releases/2.1.16/solana-release/bin:/root/.foundry/bin"
RUN foundryup
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt && rm requirements.txt
COPY nginx.conf /etc/nginx/nginx.conf

# Build Ethereum side
WORKDIR /eth
ADD https://github.com/foundry-rs/forge-std.git#6853b9ec7df5dc0c213b05ae67785ad4f4baa0ea /eth/lib/forge-std
ADD https://github.com/OpenZeppelin/openzeppelin-contracts.git#a31b4a438ad9b11368976140acd7da3ae27d717d /eth/lib/openzeppelin-contracts
COPY eth/src /eth/src
COPY eth/foundry.toml /eth
RUN forge build
COPY eth/run.sh /eth 

# "Build" Solana side
WORKDIR /sol
COPY sol/run.sh /sol

# Build frontend
WORKDIR /bridge
COPY bridge/templates/ /bridge/templates
COPY bridge/app.py /bridge

# Put it all together
WORKDIR /
EXPOSE 5000
COPY launcher.py /
CMD [ \
  "parallel", \
  "--line-buffer", \
  "--tagstring", "{= $_ = \"\\033[0;3\" . (\"2m[nginx]\", \"5m[ethereum]\", \"6m[solana]\", \"3m[bridge]\")[seq() - 1] . \"\\033[0m\" =}", \
  ":::", \
  "nginx -g 'daemon off;'", \
  "bash -c 'cd /eth && ./run.sh'", \
  "bash -c 'cd /sol && ./run.sh'", \
  "python3 launcher.py" \
]
