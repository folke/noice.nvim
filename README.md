# 💼 settings.nvim

**Settings.nvim** is a lua plugin to manage global and workspace-local Neovim
settings.

## ✅ Todo

- [x] new name since people seem to use settings as a module in their config (nvim-settings??)
- [ ] split off lsp-config as separate plugin?
- [x] naming for generated emmylua
- [x] generate list of supported lsp servers
- [x] name of plugin??
- [x] importers?
- [x] keymaps
- [x] json => jsonc for settings files
- [x] commands to edit json settings files
- [x] less magic for patterns (use {name = .., key = .., ...})
- [x] rename to settings.nvim??
- [x] check vscode config api
- [x] support lazy-loading of workspace.nvim and register plugins
- [x] path.join (workspace.has_file)

## ✨ Features

- configure Neovim using **JSON** files
  - global settings: `~/.config/nvim/settings.json`
  - local settings: `~/projects/foobar/.nvim.settings.json`
- live reload of your settings
- extensible plugin architecture
- built-in plugins:
  - **options:** configure global (`vim.opt`) and local (`vim.opt_local`)
    options.
  - **lsp**: configure the LSP clients using workspace settings.
- some workspace plugins support existing vscode settings read from
  `.vscode/settings.json`. For LSP for example, this means that existing
  configuration for LSP servers work out of the box.
- live-reload of your settings: whenever you change a local or global JSON
  settings file, the changes are applied immediately

## ⚡️ Requirements

- Neovim >= 0.7.2

## 📦 Installation

Install the plugin with your preferred package manager:

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use({
  "folke/settings.nvim",
  module = "settings",
  config = function()
    require("settings").setup()
  end,
})
```

## 🚀 Setup

It's important that you set up `settings.nvim` **BEFORE** `nvim-lspconfig`.

```lua
require("settings").setup({
  -- override any of the default settings here
})
require("lspconfig").sumneko_lua.setup(...)
```

## ⚙️ Configuration

**settings.nvim** comes with the following defaults:

```lua
{
  -- name of the local settings files
  local_settings = ".nvim.settings.json",
  -- name of the global settings file in your Neovim config directory
  global_settings = "settings.json",
  -- import existing settinsg from other plugins
  import = {
    vscode = true, -- local .vscode/settings.json
    coc = true, -- global/local coc-settings.json
    nlsp = true, -- nlsp-settings.nvim json settings
  },
  -- send new configuration to lsp clients when changing json settings
  live_reload = true,
  -- set the filetype to jsonc for settings files, so you can use comments
  -- make sure you have the jsonc treesitter parser installed!
  filetype_jsonc = true,
  plugins = {
    -- configures lsp clients with settings in the following order:
    -- - lua settings passed in lspconfig setup
    -- - global json settings
    -- - local json settings
    lspconfig = {
      enabled = true,
    },
    -- configures jsonls to get completion in .nvim.settings.json files
    jsonls = {
      enabled = true,
      -- only show completion in json settings for configured lsp servers
      configured_servers_only = true,
    },
    -- configures sumneko_lua to get completion of lspconfig server settings
    sumneko_lua = {
      -- by default, sumneko_lua annotations are only enabled in your neovim config directory
      enabled_for_neovim_config = true,
      -- explicitely enable adding annotations. Mostly relevant to put in your local .nvim.settings.json file
      enabled = false,
    },
  },
}
```

## 🚀 Usage

### The `:Settings` Command

### Completion and Validation for your `Json` Settings Files

### Completion and Validation for your `Lua` Settings Files

### Importing Your Existing Settings

## 📦 API

## ⭐ Acknowledgment

- [json.lua](https://github.com/actboy168/json.lua) a pure-lua JSON library for parsing `jsonc` files

## 💻 Supported Language Servers

<!-- GENERATED -->
- [x] [als](https://github.com/AdaCore/ada_language_server/tree/master/integration/vscode/ada/package.json)
- [x] [astro](https://github.com/withastro/language-tools/tree/main/packages/vscode/package.json)
- [x] [awkls](https://github.com/Beaglefoot/awk-language-server/tree/master/client/package.json)
- [x] [bashls](https://github.com/bash-lsp/bash-language-server/tree/master/vscode-client/package.json)
- [x] [clangd](https://github.com/clangd/vscode-clangd/tree/master/package.json)
- [x] [cssls](https://github.com/microsoft/vscode/tree/main/extensions/css-language-features/package.json)
- [x] [dartls](https://github.com/Dart-Code/Dart-Code/tree/master/package.json)
- [x] [denols](https://github.com/denoland/vscode_deno/tree/main/package.json)
- [x] [elixirls](https://github.com/elixir-lsp/vscode-elixir-ls/tree/master/package.json)
- [x] [elmls](https://github.com/elm-tooling/elm-language-client-vscode/tree/master/package.json)
- [x] [eslint](https://github.com/microsoft/vscode-eslint/tree/main/package.json)
- [x] [flow](https://github.com/flowtype/flow-for-vscode/tree/master/package.json)
- [x] [fsautocomplete](https://github.com/ionide/ionide-vscode-fsharp/tree/main/release/package.json)
- [x] [grammarly](https://github.com/znck/grammarly/tree/main/extension/package.json)
- [x] [haxe_language_server](https://github.com/vshaxe/vshaxe/tree/master/package.json)
- [x] [hhvm](https://github.com/slackhq/vscode-hack/tree/master/package.json)
- [x] [hie](https://github.com/alanz/vscode-hie-server/tree/master/package.json)
- [x] [html](https://github.com/microsoft/vscode/tree/main/extensions/html-language-features/package.json)
- [x] [intelephense](https://github.com/bmewburn/vscode-intelephense/tree/master/package.json)
- [x] [java_language_server](https://github.com/georgewfraser/java-language-server/tree/master/package.json)
- [x] [jdtls](https://github.com/redhat-developer/vscode-java/tree/master/package.json)
- [x] [jsonls](https://github.com/microsoft/vscode/tree/master/extensions/json-language-features/package.json)
- [x] [julials](https://github.com/julia-vscode/julia-vscode/tree/master/package.json)
- [x] [kotlin_language_server](https://github.com/fwcd/vscode-kotlin/tree/master/package.json)
- [x] [ltex](https://github.com/valentjn/vscode-ltex/develop/package.json)
- [x] [nickel_ls](https://github.com/tweag/nickel/tree/master/lsp/client-extension/package.json)
- [x] [omnisharp](https://github.com/OmniSharp/omnisharp-vscode/tree/master/package.json)
- [x] [perlls](https://github.com/richterger/Perl-LanguageServer/tree/master/clients/vscode/perl/package.json)
- [x] [perlnavigator](https://github.com/bscan/PerlNavigator/tree/main/package.json)
- [x] [perlpls](https://github.com/FractalBoy/perl-language-server/tree/master/client/package.json)
- [x] [powershell_es](https://github.com/PowerShell/vscode-powershell/tree/main/package.json)
- [x] [psalm](https://github.com/psalm/psalm-vscode-plugin/tree/master/package.json)
- [x] [puppet](https://github.com/puppetlabs/puppet-vscode/tree/main/package.json)
- [x] [purescriptls](https://github.com/nwolverson/vscode-ide-purescript/tree/master/package.json)
- [x] [pylsp](https://github.com/python-lsp/python-lsp-server/develop/pylsp/config/schema.json)
- [x] [pyright](https://github.com/microsoft/pyright/tree/master/packages/vscode-pyright/package.json)
- [x] [r_language_server](https://github.com/REditorSupport/vscode-r-lsp/tree/master/package.json)
- [x] [rescriptls](https://github.com/rescript-lang/rescript-vscode/tree/master/package.json)
- [x] [rls](https://github.com/rust-lang/vscode-rust/tree/master/package.json)
- [x] [rome](https://github.com/rome/tools/tree/main/editors/vscode/package.json)
- [x] [rust_analyzer](https://github.com/rust-analyzer/rust-analyzer/tree/master/editors/code/package.json)
- [x] [solargraph](https://github.com/castwide/vscode-solargraph/tree/master/package.json)
- [x] [solidity_ls](https://github.com/juanfranblanco/vscode-solidity/tree/master/package.json)
- [x] [sorbet](https://github.com/sorbet/sorbet/tree/master/vscode_extension/package.json)
- [x] [sourcekit](https://github.com/swift-server/vscode-swift/tree/main/package.json)
- [x] [spectral](https://github.com/stoplightio/vscode-spectral/tree/master/package.json)
- [x] [stylelint_lsp](https://github.com/bmatcuk/coc-stylelintplus/tree/master/package.json)
- [x] [sumneko_lua](https://github.com/sumneko/vscode-lua/tree/master/package.json)
- [x] [svelte](https://github.com/sveltejs/language-tools/tree/master/packages/svelte-vscode/package.json)
- [x] [svlangserver](https://github.com/eirikpre/VSCode-SystemVerilog/tree/master/package.json)
- [x] [tailwindcss](https://github.com/tailwindlabs/tailwindcss-intellisense/tree/master/packages/vscode-tailwindcss/package.json)
- [x] [terraformls](https://github.com/hashicorp/vscode-terraform/tree/master/package.json)
- [x] [tsserver](https://github.com/microsoft/vscode/tree/main/extensions/typescript-language-features/package.json)
- [x] [volar](https://github.com/johnsoncodehk/volar/tree/master/extensions/vscode-vue-language-features/package.json)
- [x] [vuels](https://github.com/vuejs/vetur/tree/master/package.json)
- [x] [wgls_analyzer](https://github.com/wgsl-analyzer/wgsl-analyzer/tree/main/editors/code/package.json)
- [x] [yamlls](https://github.com/redhat-developer/vscode-yaml/tree/master/package.json)
- [x] [zeta_note](https://github.com/artempyanykh/zeta-note-vscode/tree/main/package.json)
- [x] [zls](https://github.com/zigtools/zls-vscode/tree/master/package.json)
