# Changelog

## [1.13.3](https://github.com/folke/noice.nvim/compare/v1.13.2...v1.13.3) (2023-05-24)


### Bug Fixes

* **overrides:** noice was leaking extmarks for stylize_markdown ([9b148a1](https://github.com/folke/noice.nvim/commit/9b148a141df7fefc66705e2e7219d11536b99288))

## [1.13.2](https://github.com/folke/noice.nvim/compare/v1.13.1...v1.13.2) (2023-05-22)


### Bug Fixes

* **treesitter:** ignore weird invalid end_col errors. Fixes [#473](https://github.com/folke/noice.nvim/issues/473) ([7e2692b](https://github.com/folke/noice.nvim/commit/7e2692b0c461da182a54ff2af4a35aea2bf8ea5c))


### Performance Improvements

* don't bufload when highlighting a buffer ([8df4cbd](https://github.com/folke/noice.nvim/commit/8df4cbdae15a915d460828710bf9ff1befb3f12d))

## [1.13.1](https://github.com/folke/noice.nvim/compare/v1.13.0...v1.13.1) (2023-05-21)


### Bug Fixes

* support older Neovim versions ([4a1ec5e](https://github.com/folke/noice.nvim/commit/4a1ec5ec0b163a365d7593d93450676b9cbcbebd))

## [1.13.0](https://github.com/folke/noice.nvim/compare/v1.12.4...v1.13.0) (2023-05-21)


### Features

* **cmp:** incude item.detail when it's not part of item.documentation ([c2a745a](https://github.com/folke/noice.nvim/commit/c2a745a26ae562f1faecbf6177ac53377d2658d5))


### Bug Fixes

* **notify:** nvim-notify replace can be an id or a record ([a9cc87b](https://github.com/folke/noice.nvim/commit/a9cc87b14e18bc3717746b45d79157c0adb43a4d))


### Performance Improvements

* cache highlighter queries ([b4eb215](https://github.com/folke/noice.nvim/commit/b4eb2155f3347377eb0c14458755ce7b7966cdb7))

## [1.12.4](https://github.com/folke/noice.nvim/compare/v1.12.3...v1.12.4) (2023-05-07)


### Bug Fixes

* **lsp:** add non-nil guard to setup function ([#454](https://github.com/folke/noice.nvim/issues/454)) ([4524216](https://github.com/folke/noice.nvim/commit/4524216d7484c7b183ca1f654d8e66dff28a5680))
* **markdown:** conceal escaping forward slashes. Fixes [#455](https://github.com/folke/noice.nvim/issues/455) ([a7246aa](https://github.com/folke/noice.nvim/commit/a7246aa99fde34fb9d5e13c62c83ac7226514d67))

## [1.12.3](https://github.com/folke/noice.nvim/compare/v1.12.2...v1.12.3) (2023-05-04)


### Bug Fixes

* **health:** fix deprecated health checks healthcheck ([#438](https://github.com/folke/noice.nvim/issues/438)) ([0f12ed3](https://github.com/folke/noice.nvim/commit/0f12ed399e79aa49f283aa954468b92be65e03ed))
* **markdown:** replace additional html entities ([#448](https://github.com/folke/noice.nvim/issues/448)) ([d31fe94](https://github.com/folke/noice.nvim/commit/d31fe940e0866686718822aaac45527412c45134)), closes [#447](https://github.com/folke/noice.nvim/issues/447)
* **popupmenu:** only use popupmenu hl group for known item kinds. Fixes [#453](https://github.com/folke/noice.nvim/issues/453) ([0b86a7b](https://github.com/folke/noice.nvim/commit/0b86a7bfbf84927909ed81e9616a5e24602fe6fb))
* **signature:** safer lsp signature parameters ([#449](https://github.com/folke/noice.nvim/issues/449)) ([e33c346](https://github.com/folke/noice.nvim/commit/e33c34642a7b02db3db03bfc2bec7799bbc2034e))

## [1.12.2](https://github.com/folke/noice.nvim/compare/v1.12.1...v1.12.2) (2023-04-18)


### Bug Fixes

* **signature:** nil check for parameter label. Fixes [#435](https://github.com/folke/noice.nvim/issues/435) ([9d778e7](https://github.com/folke/noice.nvim/commit/9d778e7ce29c519ca0285b054e7c3b679bc9d3b9))
* **signature:** support label offsets ([9649d9f](https://github.com/folke/noice.nvim/commit/9649d9fd4d8fa8a8654e1e9c293718ae8d62e73b))

## [1.12.1](https://github.com/folke/noice.nvim/compare/v1.12.0...v1.12.1) (2023-04-17)


### Bug Fixes

* **router:** properly disable updater when disabling Noice. Fixes [#423](https://github.com/folke/noice.nvim/issues/423) ([3bed83b](https://github.com/folke/noice.nvim/commit/3bed83b4d2e4fce03a27071c39be0d9e04313332))

## [1.12.0](https://github.com/folke/noice.nvim/compare/v1.11.0...v1.12.0) (2023-04-16)


### Features

* added `Noice dismiss` to hide all visible messages. Fixes [#417](https://github.com/folke/noice.nvim/issues/417) ([a32bc89](https://github.com/folke/noice.nvim/commit/a32bc892aadb26668fd0161962ae4eccb1bf5854))

## [1.11.0](https://github.com/folke/noice.nvim/compare/v1.10.2...v1.11.0) (2023-04-16)


### Features

* **lsp:** added config.lsp.hover.silent. Fixes [#412](https://github.com/folke/noice.nvim/issues/412) ([e2a53cf](https://github.com/folke/noice.nvim/commit/e2a53cf946d88d87cd0123711afce5ddad047b7b))
* **signature:** added signature param docs. Fixes [#421](https://github.com/folke/noice.nvim/issues/421) ([e76ae13](https://github.com/folke/noice.nvim/commit/e76ae13dd272dc23d0154b93172d445aeabad8f1))


### Bug Fixes

* **confirm:** keep newlines in confirm message. Fixes [#422](https://github.com/folke/noice.nvim/issues/422) ([051111f](https://github.com/folke/noice.nvim/commit/051111f98d7128c833eaa32423426829981b2aa3))
* **markdown:** replace `&lt;code&gt;`. Fixes [#424](https://github.com/folke/noice.nvim/issues/424) ([38fb652](https://github.com/folke/noice.nvim/commit/38fb652d0a95780d20a551a6ec44b01226476c99))
* **markdown:** revert ([d767be9](https://github.com/folke/noice.nvim/commit/d767be960e8660b19595ccff2dad6abd7aae2d4a))

## [1.10.2](https://github.com/folke/noice.nvim/compare/v1.10.1...v1.10.2) (2023-03-26)


### Bug Fixes

* **icons:** removed all obsolete icons thanks to nerdfix ([cf6a194](https://github.com/folke/noice.nvim/commit/cf6a194f9280cda1fdcc36d271fccd4a24082df3))

## [1.10.1](https://github.com/folke/noice.nvim/compare/v1.10.0...v1.10.1) (2023-03-24)


### Bug Fixes

* **treesitter:** deprecated call. Fixes [#408](https://github.com/folke/noice.nvim/issues/408) ([1ded575](https://github.com/folke/noice.nvim/commit/1ded575928752861558a729fcbbd1e6e53c76652))

## [1.10.0](https://github.com/folke/noice.nvim/compare/v1.9.5...v1.10.0) (2023-03-23)


### Features

* **cmdline:** added cmdline support for `:lua=` and `:=` ([acfa513](https://github.com/folke/noice.nvim/commit/acfa5133da31a35ec24fca0757ad1c85edc4c585))

## [1.9.5](https://github.com/folke/noice.nvim/compare/v1.9.4...v1.9.5) (2023-03-19)


### Bug Fixes

* **views:** dont highlight CurSearch for some views. Fixes [#399](https://github.com/folke/noice.nvim/issues/399) ([0c493e5](https://github.com/folke/noice.nvim/commit/0c493e5d243c39adf3d6ce7683a16e610cc44e0a))

## [1.9.4](https://github.com/folke/noice.nvim/compare/v1.9.3...v1.9.4) (2023-03-15)


### Bug Fixes

* **markdown:** better check to see if a ts parser is available. Fixes [#397](https://github.com/folke/noice.nvim/issues/397) ([d60bee1](https://github.com/folke/noice.nvim/commit/d60bee1b85af1882768af80385bc2500d495feba))
* **markdown:** strip "\r" chars ([4d2801b](https://github.com/folke/noice.nvim/commit/4d2801babc4026229c58f0c77a20ff5b7b4c0d07))

## [1.9.3](https://github.com/folke/noice.nvim/compare/v1.9.2...v1.9.3) (2023-03-14)


### Bug Fixes

* **cmdline:** dont use normal commands so ModeChanged will trigger correctly. Fixes [#390](https://github.com/folke/noice.nvim/issues/390) ([fa7b6a1](https://github.com/folke/noice.nvim/commit/fa7b6a18c5cdc23961038bc56b93495efcd0f5c7))

## [1.9.2](https://github.com/folke/noice.nvim/compare/v1.9.1...v1.9.2) (2023-03-12)


### Bug Fixes

* **cmdline:** make sure cursor is always visible ([2f0a427](https://github.com/folke/noice.nvim/commit/2f0a42701b4aa65b55fff8f32878d9adc7e7ac77))
* **config:** allow overriding options set by presets ([5a1bf17](https://github.com/folke/noice.nvim/commit/5a1bf1707f592fefff4cb3da903b17369e088cc1))
* **config:** correctly set the presets ([e5cb84f](https://github.com/folke/noice.nvim/commit/e5cb84f1ed524f850fa92e3a256e830ed07fadee))

## [1.9.1](https://github.com/folke/noice.nvim/compare/v1.9.0...v1.9.1) (2023-03-03)


### Bug Fixes

* **health:** correctly check if lsp.message is enabled ([#381](https://github.com/folke/noice.nvim/issues/381)) ([1ff6b10](https://github.com/folke/noice.nvim/commit/1ff6b10471590331cc1585ad64f084f19cd4bcb7))

## [1.9.0](https://github.com/folke/noice.nvim/compare/v1.8.3...v1.9.0) (2023-03-03)


### Features

* **lsp:** fallback to buffer filetype for code blocks without lang. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([cab2c80](https://github.com/folke/noice.nvim/commit/cab2c80497388735c9795f496a36e76bc5c7c4bf))


### Bug Fixes

* **treesitter:** use the new treesitter ft to lang API if availble. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([36d141b](https://github.com/folke/noice.nvim/commit/36d141bd5852b10e32058e259982182b9e5e8060))

## [1.8.3](https://github.com/folke/noice.nvim/compare/v1.8.2...v1.8.3) (2023-03-02)


### Bug Fixes

* **notify:** take col offsets into account for nvim-notify renderers. Fixes [#375](https://github.com/folke/noice.nvim/issues/375) ([20596d9](https://github.com/folke/noice.nvim/commit/20596d96551605f7462f5722198b188e4047b605))

## [1.8.2](https://github.com/folke/noice.nvim/compare/v1.8.1...v1.8.2) (2023-02-07)


### Bug Fixes

* **signature:** when loading, attach to existing lsp clients. Fixes [#342](https://github.com/folke/noice.nvim/issues/342) ([f69f1a5](https://github.com/folke/noice.nvim/commit/f69f1a577615a5a6527f133df0aa40e596bd1707))

## [1.8.1](https://github.com/folke/noice.nvim/compare/v1.8.0...v1.8.1) (2023-02-06)


### Bug Fixes

* **ui:** cmdline is always blocking. Fixes [#347](https://github.com/folke/noice.nvim/issues/347) ([6702d97](https://github.com/folke/noice.nvim/commit/6702d97d3c37c3a363ffc7c890578109f82f9f20))

## [1.8.0](https://github.com/folke/noice.nvim/compare/v1.7.1...v1.8.0) (2023-01-24)


### Features

* added deactivate ([bf216e0](https://github.com/folke/noice.nvim/commit/bf216e017979f8be712b1ada62736a58e75b0fe3))


### Bug Fixes

* Allow mapping &lt;esc&gt; ([#329](https://github.com/folke/noice.nvim/issues/329)) ([b7e9054](https://github.com/folke/noice.nvim/commit/b7e9054b02b5958db8bb5ad7675e92bfb5a8e903))

## [1.7.1](https://github.com/folke/noice.nvim/compare/v1.7.0...v1.7.1) (2023-01-23)


### Bug Fixes

* **nui:** make sure nui recreates buffer and window when needed ([3e6dfd8](https://github.com/folke/noice.nvim/commit/3e6dfd8bb00d98399704a020ab7892234ce80fdb))
* **nui:** mount if buffer is no longer valid ([71d7b5c](https://github.com/folke/noice.nvim/commit/71d7b5cf8f24b9bdc425934c36cfda784fcd10f2))
* **nui:** set mounted=false if buffer is no longer valid ([3353a7a](https://github.com/folke/noice.nvim/commit/3353a7ab4bae6c22f61fd646c10e336b4582f0ea))


### Performance Improvements

* make noice a bit more robust when exiting to prevent possible delays on exit ([35e3664](https://github.com/folke/noice.nvim/commit/35e3664297096d8e24ca17f590bc793482f5182d))

## [1.7.0](https://github.com/folke/noice.nvim/compare/v1.6.2...v1.7.0) (2023-01-14)


### Features

* **ui:** added hybrid messages functionality, but not needed for now ([addc0a2](https://github.com/folke/noice.nvim/commit/addc0a2521ce666a1f546f9a04574a63a858c6a5))


### Bug Fixes

* **swap:** additionally check for updates when a swap file was found ([1165d3e](https://github.com/folke/noice.nvim/commit/1165d3e727bdd226eefffcc801d563bcb30e71c4))
* **ui:** work-around for segfaults in TUI. Fixes [#298](https://github.com/folke/noice.nvim/issues/298) ([176ec31](https://github.com/folke/noice.nvim/commit/176ec31026ec4baf64638fba1a180701257380f1))

## [1.6.2](https://github.com/folke/noice.nvim/compare/v1.6.1...v1.6.2) (2023-01-13)


### Bug Fixes

* **ui_attach:** dont update router during `ext_messages` and disable/enable Noice during confirm. [#298](https://github.com/folke/noice.nvim/issues/298) ([a4cbc0f](https://github.com/folke/noice.nvim/commit/a4cbc0f0cebdaa9529a749f4463aedc5a2cdcf1b))

## [1.6.1](https://github.com/folke/noice.nvim/compare/v1.6.0...v1.6.1) (2023-01-10)


### Bug Fixes

* show unstable message after loading noice ([2613a16](https://github.com/folke/noice.nvim/commit/2613a16b5009acbf2adabb34b029b1c4c57101e3))

## [1.6.0](https://github.com/folke/noice.nvim/compare/v1.5.2...v1.6.0) (2023-01-10)


### Features

* show warning when running with TUI rework ([cf2231b](https://github.com/folke/noice.nvim/commit/cf2231bfb691b3b58d2685f48da11596cec1cfa3))

## [1.5.2](https://github.com/folke/noice.nvim/compare/v1.5.1...v1.5.2) (2023-01-01)


### Bug Fixes

* **treesitter:** only disable injections for php and html ([0e1bf11](https://github.com/folke/noice.nvim/commit/0e1bf11d46054b8ab04eb62b53c5ac81b44f14df))

## [1.5.1](https://github.com/folke/noice.nvim/compare/v1.5.0...v1.5.1) (2022-12-31)


### Bug Fixes

* dont error in checkhealth if nvim-treesitter is not installed ([044767a](https://github.com/folke/noice.nvim/commit/044767a01d38208c32d97b0214cce66c41e8f7c8))
* **health:** dont use nvim-treesitter to check if a lang exists ([585d24e](https://github.com/folke/noice.nvim/commit/585d24ec6e3fb4288414f864cfe2de7d025e8216))
* **notify_send:** properly close file descriptors from spwaning notifysend ([f5132fa](https://github.com/folke/noice.nvim/commit/f5132fa6eb71e96d9f0cd7148b186b324b142d15))
* **nui:** dont trigger autocmds when doing zt ([d176765](https://github.com/folke/noice.nvim/commit/d176765ceabae9a12bf09a5c785d3dcb3859e1b6))
* **popupmenu:** replace any newlines by space. Fixes [#265](https://github.com/folke/noice.nvim/issues/265) ([5199089](https://github.com/folke/noice.nvim/commit/51990892e1dd5ee1a1444b1cf3ccf0aca377e0c4))
* **treesitter:** dont allow recursive injections. Fixes [#286](https://github.com/folke/noice.nvim/issues/286) ([a31b41a](https://github.com/folke/noice.nvim/commit/a31b41a739731988fc30a48a3099586a884bdf61))

## [1.5.0](https://github.com/folke/noice.nvim/compare/v1.4.2...v1.5.0) (2022-12-21)


### Features

* added `Filter.cond` to conditionally use a route ([29a2e05](https://github.com/folke/noice.nvim/commit/29a2e052d2653443716a8eece89300e9b36b5f2a))
* **format:** allow `config.format.level.icons` to be false. Fixes [#274](https://github.com/folke/noice.nvim/issues/274) ([aa68eb6](https://github.com/folke/noice.nvim/commit/aa68eb6f83c48df41bab8ae36623e5af3f224c66))


### Bug Fixes

* correctly apply padding based on four numbers ([c9c1fbd](https://github.com/folke/noice.nvim/commit/c9c1fbd605388badcfa62c0b7f58d184f19e1484))
* **nui:** removed work-around for padding and border style shadow ([4f34d33](https://github.com/folke/noice.nvim/commit/4f34d33fc3dc0d6f4da9b4b8c63b9714fd4eea79))

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
