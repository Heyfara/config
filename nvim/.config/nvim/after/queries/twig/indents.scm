; Indentation pour Twig (grammaire plate : blocs non imbriqués)

; Ouvertures de bloc
(for_statement) @indent.begin
(if_statement) @indent.begin

; Tags appariés ({% block %}, {% macro %}, {% set x %}...{% endset %}, etc.)
((tag_statement (tag) @_open) @indent.begin
  (#any-of? @_open
    "block" "macro" "embed" "apply" "filter" "autoescape"
    "with" "set" "spaceless" "verbatim" "sandbox" "cache"))

; else / elseif : on dédente la ligne du branch puis on ré-indente après
((tag_statement (conditional) @_branch) @indent.branch
  (#any-of? @_branch "else" "elseif"))

; Fermetures : endfor / endif / endblock / endset / ...
((tag_statement (conditional) @_c) @indent.end
  (#match? @_c "^end"))
((tag_statement (repeat) @_r) @indent.end
  (#match? @_r "^end"))
((tag_statement (tag) @_t) @indent.end
  (#match? @_t "^end"))
