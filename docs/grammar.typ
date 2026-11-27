// Read the annotated EBNF directly from the spec: no second grammar to maintain.
#let parse-rules(body) = {
  let result = ()
  let meaning = none
  let lines = ()
  let finish(meaning, lines) = {
    assert(meaning != none, message: "每条文法定义之前必须有中文 (* 说明 *)")
    let code = lines.join("\n")
    let declaration = code.match(regex("^([A-Za-z][A-Za-z0-9]*) ="))
    assert(declaration != none and code.ends-with(";"), message: "文法定义格式错误：" + code)
    let name = declaration.captures.first()
    let rhs = code.split("=").slice(1).join("=")
    // Quoted terminals and prose primitives are opaque, including backslashes.
    let tokens = rhs.matches(regex("\"[^\"]*\"|'[^']*'|\?[^?]*\?|[A-Za-z][A-Za-z0-9]*"))
    let deps = ()
    for token in tokens {
      if token.text.match(regex("^[A-Za-z][A-Za-z0-9]*$")) != none and token.text not in deps {
        deps.push(token.text)
      }
    }
    (name: name, meaning: meaning, code: code, deps: deps)
  }
  for line in body.split("\n") {
    let clean = line.trim()
    if clean == "" { continue }
    let note = clean.match(regex("^\(\* (.*) \*\)$"))
    if note != none {
      if lines.len() > 0 {
        result.push(finish(meaning, lines))
        lines = ()
      }
      meaning = note.captures.first()
    } else {
      lines.push(line)
    }
  }
  if lines.len() > 0 { result.push(finish(meaning, lines)) }
  result
}

// Follow dependencies once per name, including the names of the starting set.
#let grammar-closure(names, rules) = {
  let seen = names
  let cursor = 0
  while cursor < seen.len() {
    let name = seen.at(cursor)
    cursor += 1
    for dep in rules.at(name).deps {
      if dep not in seen { seen.push(dep) }
    }
  }
  seen
}

#let grammar-catalog(source) = {
  let blocks = ()
  let rules = (:)
  let chapter = none
  let section = none
  let lines = none
  for line in source.split("\n") {
    let clean = line.trim()
    if lines != none {
      if clean == "```" {
        let parsed = parse-rules(lines.join("\n"))
        let names = parsed.map(rule => rule.name)
        for rule in parsed {
          assert(rule.name not in rules, message: "重复文法定义：" + rule.name)
          rules.insert(rule.name, rule + (section: section, block: blocks.len(), order: rules.len()))
        }
        blocks.push(names)
        lines = none
      } else {
        lines.push(line)
      }
    } else if clean == "```ebnf" {
      assert(chapter == "ch-grammar", message: "全部 EBNF 必须集中在第 0 章文法中")
      assert(section != none, message: "文法块必须位于带标签的小节中")
      lines = ()
    } else if clean.starts-with("= ") {
      let heading = clean.match(regex("<([^>]+)>$"))
      chapter = if heading == none { none } else { heading.captures.first() }
      section = none
    } else if clean.starts-with("== ") or clean.starts-with("=== ") {
      let heading = clean.match(regex("<([^>]+)>$"))
      if heading != none { section = heading.captures.first() }
    }
  }
  assert(lines == none, message: "EBNF 代码块未闭合")
  for (name, rule) in rules {
    for dep in rule.deps {
      assert(dep in rules, message: name + " 引用了未定义文法 " + dep)
    }
  }
  for (name, rule) in rules {
    for dep in rule.deps {
      let target = rules.at(dep)
      assert(target.block <= rule.block,
        message: name + " 依赖后文文法 " + dep + "；请先定义依赖，或将相互递归的产生式合并为一组")
      if target.order > rule.order {
        assert(name in grammar-closure((dep,), rules),
          message: name + " 与 " + dep + " 不相互递归；请先定义 " + dep)
      }
    }
  }
  (blocks: blocks, rules: rules)
}

// Link nonterminal names in place. Terminals and prose atoms remain literal.
#let grammar-code(code, catalog) = {
  let tokens = regex("\"[^\"]*\"|'[^']*'|\?[^?]*\?|[A-Za-z][A-Za-z0-9]*|[^A-Za-z\"'?]+")
  for (i, line) in code.split("\n").enumerate() {
    if i > 0 { linebreak() }
    for token in line.matches(tokens) {
      let body = raw(token.text, lang: "text")
      if token.text in catalog.rules {
        link(label("grammar-" + token.text), body)
      } else {
        body
      }
    }
  }
}

#let grammar-block(it, catalog, mono, cjk, accent, pale) = {
  let local = parse-rules(it.text)
  let names = local.map(rule => rule.name)
  let current = catalog.rules.at(names.first()).block
  assert(names == catalog.blocks.at(current), message: "显示文法与源文法不一致")
  metadata((kind: "grammar-group", roots: names))
  set par(justify: false, leading: 0.45em, spacing: 0pt)
  set text(font: (mono, cjk), size: 8.5pt, hyphenate: false)
  set smartquote(enabled: false)
  // Each definition keeps its explanation; the group can break between rules.
  for rule in local {
    [#block(width: 100%, breakable: false, fill: pale, inset: 8pt,
      radius: 2pt, above: 4pt, below: 4pt)[
      #metadata((kind: "grammar-rule", name: rule.name, dependencies: rule.deps))
      #text(font: cjk, size: 9pt, fill: accent, rule.meaning)
      #linebreak()
      #grammar-code(rule.code, catalog)
    ]
    #label("grammar-" + rule.name)]
  }
}
