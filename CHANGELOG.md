# Changelog

## [1.4.0](https://github.com/folke/noice.nvim/compare/v1.3.1...v1.4.0) (2022-12-03)


### Features

* added support for &lt;pre&gt;{lang} code blocks used in the Neovim codebase ([de48a45](https://github.com/folke/noice.nvim/commit/de48a4528aad5c7b50cf4b4ec1b419762a95934d))


### Bug Fixes

* check if loader returned a function before loading ([66946c7](https://github.com/folke/noice.nvim/commit/66946c72f0a36f37e480b5eae97aac3cdcd5961d))
* reset preloader before trying to load the module ([08655e9](https://github.com/folke/noice.nvim/commit/08655e9f1bed638f9871d76b05928da74d1eeb68))

## [1.3.1](https://github.com/folke/noice.nvim/compare/v1.3.0...v1.3.1) (2022-12-01)


### Bug Fixes

* dont error if cmp not loaded when overriding ([4bae487](https://github.com/folke/noice.nvim/commit/4bae48798424d300e204cce2eb73b087854472d5))
* wait to override cmp till it loaded ([712180f](https://github.com/folke/noice.nvim/commit/712180f94684b7ce56957df60d037c81784e69c3))
