# Very basic Emacs config
{ config, lib, ... }: {
  options.hly.emacs.base = lib.mkEnableOption "Common denominator Emacs config";
  config = lib.mkIf config.hly.emacs.base {
    programs.emacs = {
      enable = true;
      extraPackages =
        e: with e; [
          dockerfile-mode
          # gnu-apl-mode
          go-mode
          htmlize
          idris-mode
          just-mode
          markdown-mode
          nix-mode
          rust-mode
          swift-mode
          terraform-mode
          web-mode
          yaml-mode

          # ocaml semantics
          ocaml-eglot # lsp integration for ocaml
          # ocaml syntax
          neocaml

          aio
          async
          async-await
          auto-compile
          avy
          company
          coverage
          diff-hl

          ripgrep
          slime
          tree-sitter
          tree-sitter-indent
          tree-sitter-langs
          treesit-grammars.with-all-grammars
          treemacs
          treemacs-all-the-icons
          treemacs-evil
          undo-tree
          vterm
          wgrep # built-in to emacs 31?

          # ... what is all this? 😂
          vertico
          consult
          embark-consult
          marginalia
          embark
          orderless
        ];
    };
  };
}
