FROM gcr.io/paradigmxyz/ctf/cairo-base:latest

COPY deploy/ /home/ctf/

COPY contracts /tmp/contracts

RUN true \
    && mkdir /home/ctf/compiled \
    && cd /tmp/contracts \
    && starknet-compile --debug_info_with_source riddle.cairo > /home/ctf/compiled/riddle.cairo \
    && rm -rf /tmp/contracts \
    && true
