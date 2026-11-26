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
    let line = line.trim()
    if line == "" { continue }
    let note = line.match(regex("^\(\* (.*) \*\)$"))
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
      assert(section != none, message: "文法块必须位于带标签的小节中")
      lines = ()
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

// References outside a jointly defined group always resolve to earlier groups.
#let grammar-dependencies(names, catalog) = {
  grammar-closure(names, catalog.rules).filter(name => name not in names)
}

#let grammar-panel(it, catalog, mono, cjk, accent, pale) = {
  let local = parse-rules(it.text)
  let names = local.map(rule => rule.name)
  let current = catalog.rules.at(names.first()).block
  assert(names == catalog.blocks.at(current), message: "显示文法与源文法不一致")
  let deps = grammar-dependencies(names, catalog)
  let direct = local.map(rule => rule.deps).flatten()
  metadata((kind: "grammar-dependencies", roots: names, dependencies: deps))

  let recursive = local.any(rule => rule.deps.any(dep =>
    catalog.rules.at(dep).order > catalog.rules.at(rule.name).order))
  if recursive {
    // Introduce every name before the mutually recursive definitions.
    block(above: 0.8em, below: 0.4em, sticky: true)[
      #text(font: cjk, size: 9pt, weight: "bold", fill: accent, "本组共同定义的名称")
    ]
    grid(
      columns: (auto, 1fr),
      column-gutter: 10pt,
      row-gutter: 3pt,
      ..local.map(rule => (
        link(label("grammar-" + rule.name), text(font: mono, size: 8pt, rule.name)),
        text(font: cjk, size: 8pt, rule.meaning),
      )).flatten(),
    )
  }

  let main = {
    set par(justify: false, leading: 0.4em, spacing: 0pt)
    set text(font: (mono, cjk), size: 8pt, hyphenate: false)
    set smartquote(enabled: false)
    for rule in local {
      block(breakable: false, above: 0pt, below: 7pt)[
        #text(font: cjk, size: 8pt, fill: accent, rule.meaning)
        #linebreak()
        #for (i, line) in rule.code.split("\n").enumerate() {
          if i > 0 { linebreak() }
          text(line)
        }
        #label("grammar-" + rule.name)
      ]
    }
  }
  let sidebar = {
    set text(font: cjk, size: 7.5pt)
    set par(justify: false, leading: 0.3em, spacing: 0pt)
    set smartquote(enabled: false)
    if deps.len() == 0 {
      [本块所需文法均已就地列出。]
    } else {
      for name in deps {
        let rule = catalog.rules.at(name)
        block(breakable: false, above: 0pt, below: 4pt)[
          #link(label("grammar-" + name), text(font: mono, size: 7.5pt, name))
          #text(fill: accent, if name in direct { "直接" } else { "间接" })
          #linebreak()
          #rule.meaning #ref(label(rule.section))
          #linebreak()
          #text(font: (mono, cjk), size: 7pt, hyphenate: false, rule.code.split("\n").join(" "))
        ]
      }
    }
  }
  // The cells may continue onto following pages; never shrink the whole block.
  block(width: 100%, breakable: true, above: 0.8em, below: 0.8em)[
    #grid(
      columns: (1.65fr, 1fr),
      column-gutter: 7pt,
      inset: 7pt,
      fill: (x, y) => if x == 0 { pale } else { rgb("f5f8f8") },
      grid.header(
        text(font: cjk, size: 8pt, weight: "bold", fill: accent, "文法与中文说明"),
        text(font: cjk, size: 8pt, weight: "bold", fill: accent, "递归依赖速查"),
      ),
      grid.cell(breakable: true, main),
      grid.cell(breakable: true, sidebar),
    )
  ]
}
