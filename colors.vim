" Noice.nvim Highlight Groups
" This file contains all highlight groups defined by noice.nvim
" with comments about their purpose and default links

" Cmdline related highlights
highlight! link NoiceCmdline MsgArea              " Normal highlight for the classic cmdline area at the bottom
highlight! link NoiceCmdlineIcon DiagnosticSignInfo " Icon shown in the cmdline
highlight! link NoiceCmdlineIconSearch DiagnosticSignWarn " Icon shown for search commands (/ and ?)
highlight! link NoiceCmdlinePrompt Title         " Prompt for input() command
highlight! link NoiceCmdlinePopup Normal         " Normal highlight for the cmdline popup
highlight! link NoiceCmdlinePopupBorder DiagnosticSignInfo " Border for the cmdline popup
highlight! link NoiceCmdlinePopupTitle DiagnosticSignInfo " Title of the cmdline popup
highlight! link NoiceCmdlinePopupBorderSearch DiagnosticSignWarn " Border for search cmdline popup
highlight! link NoiceCmdlineCommand Statement " Highlight for the command (first word) in the cmdline

" View specific highlights
highlight! link NoiceConfirm Normal              " Normal highlight for the confirm view
highlight! link NoiceConfirmBorder DiagnosticSignInfo " Border for the confirm view
highlight! link NoiceCursor Cursor               " Fake cursor used in UI
highlight! link NoiceMini MsgArea                " Normal highlight for mini view
highlight! link NoicePopup NormalFloat           " Normal highlight for popup views
highlight! link NoicePopupBorder FloatBorder     " Border for popup views 
highlight! link NoiceSplit NormalFloat           " Normal highlight for split views
highlight! link NoiceSplitBorder FloatBorder     " Border for split views
highlight! link NoiceVirtualText DiagnosticVirtualTextInfo " Default highlight for virtualtext views

" Popupmenu related highlights
highlight! link NoicePopupmenu Pmenu             " Normal highlight for the popupmenu
highlight! link NoicePopupmenuBorder FloatBorder " Border for the popupmenu
highlight! link NoicePopupmenuMatch Special      " Part of the item that matches the input
highlight! link NoicePopupmenuSelected PmenuSel  " Selected item in the popupmenu

" Scrollbar highlights
highlight! link NoiceScrollbar PmenuSbar         " Normal highlight for scrollbar
highlight! link NoiceScrollbarThumb PmenuThumb   " Scrollbar thumb

" Format related highlights
highlight! link NoiceFormatProgressDone Search   " Progress bar completed portion
highlight! link NoiceFormatProgressTodo CursorLine " Progress bar todo portion
highlight! link NoiceFormatEvent NonText         " Event formatting
highlight! link NoiceFormatKind NonText          " Kind formatting
highlight! link NoiceFormatDate Special          " Date formatting
highlight! link NoiceFormatConfirm CursorLine    " Confirm formatting
highlight! link NoiceFormatConfirmDefault Visual " Default confirm option
highlight! link NoiceFormatTitle Title           " Title formatting

" Log level highlights
highlight! link NoiceFormatLevelDebug NonText    " Debug level messages
highlight! link NoiceFormatLevelTrace NonText    " Trace level messages
highlight! link NoiceFormatLevelOff NonText      " Off level messages
highlight! link NoiceFormatLevelInfo DiagnosticVirtualTextInfo " Info level messages
highlight! link NoiceFormatLevelWarn DiagnosticVirtualTextWarn " Warning level messages
highlight! link NoiceFormatLevelError DiagnosticVirtualTextError " Error level messages

" LSP progress highlights
highlight! link NoiceLspProgressSpinner Constant " Spinner for LSP progress notifications
highlight! link NoiceLspProgressTitle NonText    " Title for LSP progress notifications
highlight! link NoiceLspProgressClient Title     " Client name for LSP progress notifications

" Completion item highlights
highlight! link NoiceCompletionItemMenu NONE     " Normal highlight for completion menu
highlight! link NoiceCompletionItemWord NONE     " Normal highlight for completion word

" Completion item kind highlights (all linked to Special by default)
highlight! link NoiceCompletionItemKindDefault Special " Default highlight for completion kinds
highlight! link NoiceCompletionItemKindColor NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindFunction NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindClass NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindMethod NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindConstructor NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindInterface NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindModule NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindStruct NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindKeyword NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindValue NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindProperty NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindConstant NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindSnippet NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindFolder NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindText NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindEnumMember NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindUnit NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindField NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindFile NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindVariable NoiceCompletionItemKindDefault
highlight! link NoiceCompletionItemKindEnum NoiceCompletionItemKindDefault

" Special highlight with blend=100 and nocombine=true for hidden cursor
" This can't be expressed as a link, so it would need to be defined in your colorscheme
" highlight NoiceHiddenCursor guibg=NONE guifg=NONE gui=nocombine blend=100