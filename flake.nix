{
  description = "Luca's simple Neovim flake for easy configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/flake-utils";
    };
    neovim-flake = {
      url = "github:neovim/neovim?dir=contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Theme
    "plugin:doom-one-nvim" = {
      url = "github:NTBBloodbath/doom-one.nvim";
      flake = false;
    };
    "plugin:onedark-vim" = {
      url = "github:joshdick/onedark.vim";
      flake = false;
    };
    # Neorg
    "plugin:neorg" = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
    # Headlines
    "plugin:headlines-nvim" = {
      url = "github:lukas-reineke/headlines.nvim";
      flake = false;
    };
    # Git
    "plugin:gitsigns" = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    # Plenary
    "plugin:plenary.nvim" = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    # neovim-nix
    "plugin:vim-nix" = {
      url = "github:LnL7/vim-nix";
      flake = false;
    };
    # VimTeX
    "plugin:vimtex" = {
      url = "github:lervag/vimtex";
      flake = false;
    };
    # FTerm.nvim
    "plugin:FTerm.nvim" = {
      url = "github:numToStr/FTerm.nvim";
      flake = false;
    };
    # Neo-Tree
    "plugin:neo-tree.nvim" = {
      url = "github:nvim-neo-tree/neo-tree.nvim";
      flake = false;
    };
    # ALE
    "plugin:ale" = {
      url = "github:dense-analysis/ale";
      flake = false;
    };
    # Hop
    "plugin:hop.nvim" = {
      url = "github:phaazon/hop.nvim";
      flake = false;
    };
    # Nerdcommenter
    "plugin:nerdcoommenter" = {
      url = "github:preservim/nerdcommenter";
      flake = false;
    };
    # Indent-Blankline
    "plugin:indent-blankline.nvim" = {
      url = "github:lukas-reineke/indent-blankline.nvim";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
  # This line makes this package availeable for all systems
  # ("x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin",...)
    flake-utils.lib.eachDefaultSystem (
      system: let
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a map of our plugins.
        # Each input in the format:
        # ```
        # "plugin:yourPluginName" = {
        #   url   = "github:exampleAuthor/examplePlugin";
        #   flake = false;
        # };
        # ```
        # included in the `inputs` section is packaged to a (neo-)vim
        # plugin and can then be used via
        # ```
        # pkgs.neovimPlugins.yourPluginName
        # ```
        pluginOverlay = final: prev: let
          inherit (prev.vimUtils) buildVimPluginFrom2Nix;
          treesitterGrammars = prev.tree-sitter.withPlugins (_: prev.tree-sitter.allGrammars);
          plugins =
            builtins.filter
            (s: (builtins.match "plugin:.*" s) != null)
            (builtins.attrNames inputs);
          plugName = input:
            builtins.substring
            (builtins.stringLength "plugin:")
            (builtins.stringLength input)
            input;
          buildPlug = name:
            buildVimPluginFrom2Nix {
              pname = plugName name;
              version = "master";
              src = builtins.getAttr name inputs;

              # Tree-sitter fails for a variety of lang grammars unless using :TSUpdate
              # For now install imperatively
              #postPatch =
              #  if (name == "nvim-treesitter") then ''
              #    rm -r parser
              #    ln -s ${treesitterGrammars} parser
              #  '' else "";
            };
        in {
          neovimPlugins = builtins.listToAttrs (map
            (plugin: {
              name = plugName plugin;
              value = buildPlug plugin;
            })
            plugins);
        };

        # Apply the overlay and load nixpkgs as `pkgs`
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            pluginOverlay
            (final: prev: {
              neovim-unwrapped = inputs.neovim-flake.packages.${prev.system}.neovim;
            })
          ];
        };

        # neovimBuilder is a function that takes your prefered
        # configuration as input and just returns a version of
        # neovim where the default config was overwritten with your
        # config.
        #
        # Parameters:
        # customRC | your init.vim as string
        # viAlias  | allow calling neovim using `vi`
        # vimAlias | allow calling neovim using `vim`
        # start    | The set of plugins to load on every startup
        #          | The list is in the form ["yourPluginName" "anotherPluginYouLike"];
        #          |
        #          | Important: The default is to load all plugins, if
        #          |            `start = [ "blabla" "blablabla" ]` is
        #          |            not passed as an argument to neovimBuilder!
        #          |
        #          | Make sure to add:
        #          | ```
        #          | "plugin:yourPluginName" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          |
        #          | "plugin:anotherPluginYouLike" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          | ```
        #          | to your imports!
        # opt      | List of optional plugins to load only when
        #          | explicitly loaded from inside neovim
        neovimBuilder = {
          customRC ? "",
          viAlias ? true,
          vimAlias ? true,
          start ? builtins.attrValues pkgs.neovimPlugins,
          opt ? [],
          debug ? false,
        }: let
          myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
            propagatedBuildInputs = with pkgs; [pkgs.stdenv.cc.cc.lib];
          });
        in
          pkgs.wrapNeovim myNeovimUnwrapped {
            inherit viAlias;
            inherit vimAlias;
            configure = {
              customRC = customRC;
              packages.myVimPackage = with pkgs.neovimPlugins; {
                start = start;
                opt = opt;
              };
            };
          };
      in rec {
        defaultApp = apps.nvim;
        defaultPackage = packages.neovimLuca;

        apps.nvim = {
          type = "app";
          program = "${defaultPackage}/bin/nvim";
        };

        packages.neovimLuca = neovimBuilder {
          # the next line loads a trivial example of a init.vim:
          customRC = pkgs.lib.readFile ./init.vim;
          # if you wish to only load the onedark-vim colorscheme:
          # start = with pkgs.neovimPlugins; [ onedark-vim ];
        };
      }
    );
}
