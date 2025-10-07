; 代码围栏（``` 或 ~~~）的外层与内层
; 外层 = 整个 fenced_code_block 节点（含围栏）
; 内层 = 仅 code_fence_content（不含围栏与 info string）
((fenced_code_block
   (code_fence_content) @codeblock.inner)
  @codeblock.outer)

; 可选：缩进式代码块（四空格）也作为 codeblock
((indented_code_block) @codeblock.inner) @codeblock.outer

