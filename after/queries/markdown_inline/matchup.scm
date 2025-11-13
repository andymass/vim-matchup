; ===========
; inline code `
; ===========
(code_span
  (code_span_delimiter) @open.code
  (code_span_delimiter) @close.code) @scope.code

; ===========================
; emphasis (italic, *...* / _..._)
; ===========================
(emphasis
  (emphasis_delimiter) @open.emphasis
  (emphasis_delimiter) @close.emphasis) @scope.emphasis

; ===========================
; strong emphasis (bold, **...** / __...__)
; ===========================
(strong_emphasis
  (emphasis_delimiter) @open.strong
  (emphasis_delimiter) @open.strong
  (emphasis_delimiter) @close.strong
  (emphasis_delimiter) @close.strong) @scope.strong

; ===========================
; strikethrough (~~...~~)
; ===========================
(strikethrough
  (emphasis_delimiter) @open.strikethrough
  (emphasis_delimiter) @close.strikethrough) @scope.strikethrough
