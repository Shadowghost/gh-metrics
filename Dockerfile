FROM node:22-bookworm-slim

COPY --from=denoland/deno:bin /deno /usr/local/bin/deno
COPY --from=pkgxdev/pkgx:busybox /usr/local/bin/pkgx /usr/local/bin/pkgx

WORKDIR /metrics

COPY . .

RUN chmod +x /metrics/source/app/action/index.mjs \
  # Install latest chrome dev package, fonts to support major charsets and skip chromium download on puppeteer install
  # Based on https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker
  && apt-get update \
  && apt-get install --no-install-recommends -y wget gnupg ca-certificates libgconf-2-4 \
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
  && apt-get update \
  && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxtst6 lsb-release --no-install-recommends \
  # Install ruby to support github licensed gem
  && apt-get install --no-install-recommends -y ruby-full git g++ cmake pkg-config libssl-dev zlib1g-dev liblzma-dev patch xz-utils make \
  && gem install licensed \
  # Install python for node-gyp
  && apt-get install -y python3 \
  # Clean apt/lists
  && rm -rf /var/lib/apt/lists/* \
  # Install node modules and rebuild indexes
  && npm ci \
  && npm run build

# Environment variables
ENV PUPPETEER_SKIP_DOWNLOAD="true"
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/google-chrome-stable"

# Execute GitHub action
ENTRYPOINT ["node", "/metrics/source/app/action/index.mjs"]
