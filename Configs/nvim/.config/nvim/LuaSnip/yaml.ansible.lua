--[[
Ansible YAML snippets {{{1
- Guard expansion to line-begin (prevents mid-line YAML breakage).
- Use fmt for clean indentation/newlines.
- Useful skeletons: task, play, block/rescue/always, section comment.
--]]

local ls = require "luasnip"
local s, t, i, c, sn = ls.snippet, ls.text_node, ls.insert_node, ls.choice_node, ls.snippet_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt
local conds = require("luasnip.extras.expand_conditions")

return {
  -- Basic Ansible task
  s(
    { trig = "task", name = "Ansible task", dscr = "Insert a basic task" },
    fmt([[
- name: {}
  {}: {}
]], {
      i(1, "Task description"),
      i(2, "module"),
      i(3, "arguments"),
    }),
    { condition = conds.line_begin }
  ),

  -- Ansible playbook skeleton
  s(
    { trig = "play", name = "Ansible playbook skeleton" },
    fmt([[
---
- name: {}
  hosts: {}
  become: {}
  gather_facts: {}
  tasks:
    - name: {}
      {}: {}
]], {
      i(1, "Playbook Name"),
      i(2, "all"),
      c(3, { t("true"), t("false") }),
      c(4, { t("true"), t("false") }),
      i(5, "First task"),
      i(6, "module"),
      i(0),
    }),
    { condition = conds.line_begin }
  ),

  -- Block / rescue / always pattern
  s(
    { trig = "block", name = "Ansible block-rescue-always" },
    fmt([[
- block:
    - name: {}
      {}: {}
  rescue:
    - debug:
        msg: "{} failed"
  always:
    - debug:
        msg: "always runs"
]], {
      i(1, "Do something"),
      i(2, "module"),
      i(3, "args"),
      rep(1),
    }),
    { condition = conds.line_begin }
  ),

  -- Section comment with fold markers (separate lines; safe for YAML)
  s(
    { trig = "asec", name = "Ansible section comment" },
    fmt([[
# {} {{{1
# End {} }}}1
]], {
      i(1, "Section"),
      rep(1),
    }),
    { condition = conds.line_begin }
  ),
}
