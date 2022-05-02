FROM gitpod/workspace-full
WORKDIR /home/gitpod
ADD ./docker/ /home/gitpod/docker
# install v8
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git \
  && export PATH=$(pwd)/depot_tools:$PATH \
  && fetch --no-history v8 \
  && cd v8 \
  && git fetch --all \
  && git checkout 10.0.139.9 \
  && gclient sync \
  && mkdir -p out/x64-linux-gcc \
  && cp ../docker/v8_args out/x64-linux-gcc/gn.args \
  && ls -lh out/x64-linux-gcc
  # && gn gen out/x64-linux-gcc \
  # && ninja -C out/x64-linux-gcc v8 \
  # && sudo cp out/x64-linux-gcc/*.so /usr/lib \
  # && sudo cp -r include/* /usr/local/include
