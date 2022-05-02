FROM gitpod/workspace-base

# Install Nix
USER root
RUN addgroup --system nixbld \
  && adduser gitpod nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown gitpod /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf \
  && echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
CMD /bin/bash -l
USER gitpod
ENV USER gitpod
WORKDIR /home/gitpod
RUN touch .bash_profile \
 && curl https://nixos.org/releases/nix/nix-2.8.0/install | sh
RUN echo '. /home/gitpod/.nix-profile/etc/profile.d/nix.sh' >> /home/gitpod/.bashrc
RUN mkdir -p /home/gitpod/.config/nixpkgs && echo '{ allowUnfree = true; }' >> /home/gitpod/.config/nixpkgs/config.nix

# Install dependencies
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
# haskell.nix
  && echo 'trusted-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=' >> /home/gitpod/.config/nix/nix.conf \
  && echo 'substituters = https://hydra.iohk.io' >> /home/gitpod/.config/nix/nix.conf \
# cachix
  && nix-env -iA cachix -f https://cachix.org/api/v1/install \
  && cachix use cachix \
# flakes
  && nix-env -iA nixpkgs.nixFlakes \
# git
  && nix-env -i git git-lfs \
# direnv
  && nix-env -i direnv \
  && direnv hook bash >> /home/gitpod/.bashrc \
# nixpkgs-fmt
  && nix-env -i nixpkgs-fmt

# Built project
ADD ./ /workspace/linear-v8
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
  && cd /workspace/linear-v8 \
  && nix build