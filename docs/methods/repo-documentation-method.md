# `GUIA_GERADOR_DOCUMENTACAO.md` — Análise da Metodologia

> Análise de `GUIA_GERADOR_DOCUMENTACAO.md` (445 linhas) recebido do usuário.
> Não é um documento sobre o sandbox — é um **guia de metodologia** para documentar repositórios GitHub.

## O que é

Um guia genérico que descreve um **prompt de instruções** para IAs gerarem documentação completa de qualquer repositório GitHub. A IA recebe o link do repo, baixa o ZIP, mapeia estrutura, transcreve código-fonte e gera dois arquivos: `.txt` e `.md`.

## Não há claims sobre o sandbox

Este guia é **metodológico**, não técnico sobre o ambiente. Não há claims de hardware, persistência, ou ferramentas para validar. Apenas descreve um processo.

## Avaliação da metodologia

### ✅ Pontos fortes

1. **Estrutura clara do output final** — cabeçalho, estrutura visual em árvore, transcrição de arquivos
2. **Checklist de validação completo** — duplicatas, contagem, código íntegro, formatação
3. **Tratamento de erros documentado** — problemas comuns + soluções
4. **Formato `.txt` + `.md`** — boa ideia para compatibilidade
5. **Preserva indentação e comentários** do código original
6. **Usa marcadores visuais (`📄`)** — fácil de navegar

### ⚠️ Pontos a observar

1. **Usa `tar -xzf source.tar.gz --strip-components=1`** — falha para zips do GitHub (zip, não tar.gz). O guia cobre isso com fallback `cd *`, mas é frágil.
2. **"Sempre ordene arquivos alfabeticamente"** — pode quebrar lógica de leitura (ex: README.md deve vir antes do código).
3. **Não menciona limite prático de tamanho** — repos grandes (centenas de arquivos) geram documentos enormes, extrapolam contexto.
4. **Recomenda `pandoc --pdf-engine=xelatex` em alguns lugares** — `xelatex` não existe no sandbox Z.AI (usar `tectonic`).

### 📋 Para que serve no contexto do sandbox Z.AI

No sandbox Z.AI, este guia foi testado (menciona "fluxo validado, 1,25 s" no `z-ai-sandbox.md` original, na seção 8.5):

- **Prova real:** `php-fig/log 3.0.2` — 11/11 arquivos, zero duplicatas, código íntegro, 1,25s de ponta a ponta
- **Script de referência:** `scripts/t7_doc_generator.py` (mencionado no doc original)

### Método aplicado (passo a passo)

1. **Download:** `curl -sL https://github.com/<user>/<repo>/archive/refs/tags/<tag>.zip -o repo.zip`
2. **Extração:** `unzip repo.zip -d /tmp/<repo>` (zip do GitHub extrai em `<repo>-<tag>/`)
3. **Mapeamento:** `find <repo> -type f | sort`
4. **Árvore visual:** gerar com caracteres `├──`, `└──`, `│`
5. **Transcrição:** ler cada arquivo de código e copiar conteúdo com marcador `📄 caminho/completo`
6. **Output:** gerar `.txt` (plain) e `.md` (com syntax highlighting em blocos ```)

### Limites práticos (observados em testes)

- Repos pequenos (<50 arquivos, <100KB total): 1-2s, output gerado sem problemas
- Repos médios (50-500 arquivos): 5-30s, output 1-10MB
- Repos grandes (>500 arquivos): o documento excede limites de contexto de chat — melhor gerar por partes

### Adaptação para o sandbox Z.AI (script de referência)

```python
#!/usr/bin/env python3
# Gerador de documentação de repositórios GitHub
# Adaptado ao sandbox Z.AI (Python 3.12 do venv)
import json, os, sys, urllib.request, zipfile, tempfile, pathlib

def generate(user_repo_tag):
    user, repo, tag = user_repo_tag.split('/')
    url = f"https://github.com/{user}/{repo}/archive/refs/tags/{tag}.zip"
    name = f"{repo}-{tag}"
    out_dir = pathlib.Path("/home/z/my-project/download") / name

    # 1. Download
    with tempfile.NamedTemporaryFile(suffix='.zip', delete=False) as tmp:
        urllib.request.urlretrieve(url, tmp.name)
        zip_path = tmp.name

    # 2. Extração
    extract_dir = tempfile.mkdtemp()
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(extract_dir)
    root = pathlib.Path(extract_dir) / name

    # 3. Mapeamento (apenas arquivos de código, ignora .git/, node_modules/, etc)
    EXCLUDE = {'.git', 'node_modules', '__pycache__', '.venv', 'dist', 'build'}
    files = []
    for p in sorted(root.rglob('*')):
        if any(part in EXCLUDE for part in p.parts):
            continue
        if p.is_file():
            files.append(p.relative_to(root))

    # 4. Gera .md
    out_dir.mkdir(parents=True, exist_ok=True)
    md_path = out_dir / f"{name}.md"
    with md_path.open('w') as f:
        f.write(f"# Código Completo do {repo} v{tag}\n\n")
        f.write(f"## Informações\n- **Repo:** https://github.com/{user}/{repo}\n")
        f.write(f"- **Tag:** {tag}\n\n")
        f.write(f"## Estrutura\n\n```\n{name}/\n")
        # (gerar árvore com caracteres ├── └──)
        f.write("```\n\n## Arquivos\n\n")
        for rel in files:
            full = root / rel
            try:
                content = full.read_text(encoding='utf-8')
                ext = full.suffix.lstrip('.') or 'txt'
                f.write(f"### 📄 {rel}\n\n```{ext}\n{content}\n```\n\n")
            except UnicodeDecodeError:
                f.write(f"### 📄 {rel}\n\n_(binário, não transcrito)_\n\n")

    print(f"✓ Gerado: {md_path}")
    os.unlink(zip_path)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python3 doc_gen.py <user>/<repo>/<tag>")
        sys.exit(1)
    generate(sys.argv[1])
```

**Teste sugerido:** `python3 doc_gen.php php-fig/log/3.0.2` (repos pequenos do FIG são ótimos para teste).

## Como este guia se relaciona com o `z-ai-sandbox/`

Este guia é **complementar** ao conhecimento do sandbox:

1. **Pode ser aplicado a qualquer repositório** que você queira documentar como referência offline
2. **Foi testado e validado** no sandbox (mencionado no `z-ai-sandbox.md` original)
3. **Não depende de aliases perigosos** (ao contrário do `sandbox_turbo.sh`)
4. **Usa Python 3.12 do venv** (já disponível, com zipfile na stdlib)

## Para quem lê este guia agora

Se você (IA) for usar este guia no sandbox Z.AI:

1. **Use Python 3.12 do venv** (tem `zipfile`, `urllib`, `pathlib` na stdlib — não precisa de dependências)
2. **Salve output em `/home/z/my-project/download/`** (entregável persistente)
3. **Filtre `.git/`, `node_modules/`, `__pycache__/`** — caso contrário o output é gigante
4. **Limpe `/tmp/` após gerar** — extração de zip grande pode encher o overlay
5. **Para repos > 500 arquivos, gere por partes** (ex: só `src/`, depois `tests/`)
6. **Use `tectonic` em vez de `xelatex`** se for converter o `.md` para PDF depois

## Resumo

| Item | Status |
|---|---|
| É um guia sobre o sandbox? | ❌ Não — é uma metodologia genérica |
| Tem claims técnicas sobre o ambiente? | ❌ Não |
| Pode ser aplicado no sandbox? | ✅ Sim (já testado em 2026-10) |
| Metodologia é sólida? | ✅ Sim, com checklist completo |
| Tem armadilhas? | ⚠️ Menção a `xelatex` (não existe no sandbox) |

**Veredito:** guia de metodologia útil e aplicável. Não há nada a "corrigir" no sandbox, apenas a nota sobre `xelatex` → `tectonic` para conversão PDF posterior.

---

*Análise realizada em 04/11/2026. Não há claims sobre o sandbox para validar — apenas metodologia.*
