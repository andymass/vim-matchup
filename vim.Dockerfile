FROM debian:latest AS neovim-image
ARG NVIM_VERSION=stable
ARG NVIM_ARCH=-linux-x86_64
ADD --chmod=755 https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim${NVIM_ARCH}.appimage /nvim-linux-x86_64.appimage
RUN /nvim-linux-x86_64.appimage --appimage-extract

FROM debian:latest AS vim-image
ARG VIM_VERSION=v9.1.1287
ADD --chmod=755 https://github.com/vim/vim-appimage/releases/download/${VIM_VERSION}/Vim-${VIM_VERSION}.glibc2.29-x86_64.AppImage /vim-linux-x86_64.appimage
RUN /vim-linux-x86_64.appimage --appimage-extract

FROM rust:latest AS tree-sitter
WORKDIR /work
RUN cargo install tree-sitter-cli --root /
ADD https://github.com/tree-sitter/tree-sitter-ruby.git /work/tree-sitter-ruby
RUN cd tree-sitter-ruby \
    && tree-sitter build -o /work/ruby.so
ADD https://github.com/tree-sitter/tree-sitter-python.git /work/tree-sitter-python
RUN cd tree-sitter-python \
    && tree-sitter build -o /work/python.so

FROM python:latest AS base
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    git \
    ca-certificates \
    make

FROM base AS test-prep
WORKDIR /work
COPY test/new/requirements.txt test/new/requirements.txt
COPY test/new/Makefile test/new/Makefile
RUN cd test/new && make env
RUN mkdir -p test/vader/vader.vim && git clone --depth=1 https://github.com/junegunn/vader.vim.git test/vader/vader.vim

FROM python:latest AS nvim

WORKDIR /work
ENV HOME=/work
ENV GIT_PAGER=cat
ENV TESTS_ENABLE_TREESITTER=1

# nvim
COPY --from=neovim-image /squashfs-root /nvim-root
RUN ln -s /nvim-root/AppRun /bin/nvim

# vim
COPY --from=vim-image /squashfs-root /vim-root
RUN ln -s /vim-root/AppRun /bin/vim

COPY . .
COPY --from=test-prep /work/test test

# Treesitter
RUN mkdir -p /work/.local/share/nvim/site/parser/
COPY --from=tree-sitter /work/ruby.so /work/.local/share/nvim/site/parser/ruby.so
COPY --from=tree-sitter /work/python.so /work/.local/share/nvim/site/parser/python.so

ENTRYPOINT ["bash"]
