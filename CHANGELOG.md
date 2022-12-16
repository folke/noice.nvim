# Changelog

## [1.4.2](https://github.com/folke/noice.nvim/compare/v1.4.1...v1.4.2) (2022-12-16)


### Bug Fixes

* **debug:** calculate stacktrace outisde of vim schedule to make it useful ([a5de1ca](https://github.com/folke/noice.nvim/commit/a5de1ca0eaecd21fd33a0a191d1a0b9dd97cb54a))
* **debug:** only concat debug info that is a string ([78ec5c6](https://github.com/folke/noice.nvim/commit/78ec5c6eefb9b61056a8545ded33b99f7a9a9f72))
* **nui:** remove border text when style is `nil`, `"none"`, or `"shadow"` ([d85a4d0](https://github.com/folke/noice.nvim/commit/d85a4d01774b5649dbcda8526a26f201dff5ade4))
* **nui:** remove padding when border is `shadow` ([1515007](https://github.com/folke/noice.nvim/commit/151500759722c12fb6a3931c5243d68f01af007a))

## [1.4.1](https://github.com/folke/noice.nvim/compare/v1.4.0...v1.4.1) (2022-12-03)


### Bug Fixes

* scrollbar destructs itself, so make a copy to see if there are any remnants left ([8d80a69](https://github.com/folke/noice.nvim/commit/8d80a692d5a045a3ec995536782f2b4c2b8d901b))
* stop processing messages when Neovim is exiting. Fixes [#237](https://github.com/folke/noice.nvim/issues/237) ([8c8acf7](https://github.com/folke/noice.nvim/commit/8c8acf74c09374e48a8fa1835560c3913d57243f))

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
