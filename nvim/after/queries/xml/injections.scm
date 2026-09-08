; extends

; Inject text only, leaving dynamic tags, attributes and comments to XML.
([
  (CharData)
  (CData)
] @injection.content
  (#mybatis-sql? @injection.content)
  (#set! injection.language "sql")
  (#set! injection.include-children))
