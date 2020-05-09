FROM gitpod/workspace-full

RUN bash -cl "rustup toolchain install stable && rustup target add wasm32-unknown-unknown"

RUN bash -c ". .nvm/nvm.sh \
             && nvm install v12 && nvm alias default v12 \
             && mkdir /home/gitpod/near-bin && export PATH=$PATH:/home/gitpod/near-bin"