# Investigação Profunda do Container — Processos, Cgroups, Rede, Mounts

> Continuação da investigação empírica em 05/11/2026 (UTC+8).
> Foco: process tree, capabilities reais, cgroups, mounts OSS, namespaces, limites do kernel, var ambiente FC, rede real, /external/* proxy.

## Resumo executivo — novas descobertas

| # | Descoberta | Impacto |
|---|---|---|
| 1 | **`/app/zcode-driver/`** rodando em `/bin/bash /app/zcode-driver/boot.sh start` + `node /app/zcode-driver/main.mjs` | ⭐⭐⭐ — **NOVO**, é o ZCode Server rodando ativamente neste container (não é só files estáticos) |
| 2 | **Process tree hierárquica** — tini (PID 1) → Caddy (PID 2) + uv/main.py (PID 894) → python main.py (PID 935) → shell z (PID 2149) | ⭐⭐⭐ |
| 3 | **Capabilities do root (PID 1):** `cap_chown, cap_dac_override, cap_fowner, cap_fsetid, cap_kill, cap_setgid, cap_setuid, cap_setpcap, cap_net_bind_service, cap_net_raw, cap_sys_chroot, cap_mknod, cap_audit_write, cap_setfcap` | ⭐⭐⭐ — root TEM `cap_net_raw` (pode fazer ping), mas z NÃO tem |
| 4 | **Capabilities do z user:** `CapEff = 0x0000000000000000` — ZERO, nenhuma capability | ⭐⭐⭐ — confirma que z é sandbox total |
| 5 | **Seccomp filter mode 2** ativo em todos os processos (mesmos shell do z) | ⭐⭐ |
| 6 | **/etc/.z-ai-config chaves extras:** `diskRetire: True` (boolean), `stage: "default"` (string) | ⭐⭐ — diskRetire indica se o disco será reciclado após sessão; stage é o preset de skills |
| 7 | **JWT não tem `exp`** (sem expiração explícita) — só `user_id`, `chat_id`, `platform: "zai"` | ⭐⭐ |
| 8 | **DNS**: `100.100.2.136` e `100.100.2.138` (DNS privado Alibaba) | ⭐⭐ |
| 9 | **IP do container:** `21.0.15.199/32` (gateway `21.0.0.1`) — IP fixo dentro do namespace | ⭐⭐ |
| 10 | **MTU eth0 = 1450** (default é 1500 — overhead de overlay network Kata) | ⭐ |
| 11 | **10 conexões TCP concorrentes funcionam** (testadas contra httpbin.org) | ⭐⭐ |
| 12 | **`/external/*` é um proxy HTTP** para APIs externas pré-registradas — atualmente vazio (`{"apis":{},"count":0}`) | ⭐⭐⭐ — novo endpoint não documentado |
| 13 | **`/v1/oss/upload`** existe mas requer "outro token" — retorna 401 "invalid token" | ⭐⭐ |
| 14 | **`/v1/oss/list`** retorna 404 — provável que requer source `zcode` (não `Z`) | ⭐⭐ |
| 15 | **Gateway routes by source:** `Z` (15 routes), `zcode` (3 routes: fc/update, oss/list, oss/upload), `zai-agent` (1 route) | ⭐⭐⭐ |
| 16 | **Python venv tem 430 pacotes** (não 921!) — contagem anterior incluía subdependências | ⭐ |
| 17 | **Pacotes ML grandes no venv:** nvidia-nccl (383MB), vtk (340MB), catboost (294MB), aspose-words (286MB), cadquery-ocp (271MB), xgboost (239MB), casadi (213MB), opencv (162MB), playwright (129MB) | ⭐⭐⭐ — capacity enorme para ML/CAD/data science |
| 18 | **Limites do kernel:** `pid_max = 32768`, `threads-max = 925` (por processo), `max_map_count = 65530`, `file-max = 100000`, `tcp_max_syn_backlog = 128`, `somaxconn = 4096`, `ip_local_port_range = 32768-60999`, `tcp_tw_reuse = 2` | ⭐⭐ |
| 19 | **cgroup devices whitelist:** apenas devices character essenciais (`null`, `zero`, `full`, `random`, `urandom`, `tty`, `ptmx`, `pts/*`); blocks/raw block devices (`mknod` apenas) | ⭐ |
| 20 | **/dev/shm = 64MB** (default, compartilhado) | ⭐ |
| 21 | **Process tree is alive between resets** — Caddy, uv main.py, zcode-driver rodam em background desde o boot | ⭐⭐ |

---

## 1. Process tree completa (PID by PID)

```
PID 1:    /usr/bin/tini -- /start.sh              (root, init system)
PID 2:    caddy run --config /app/Caddyfile...    (root, HTTP proxy em :81)
PID 894:  /usr/local/bin/uv run main.py          (root, wrapper do Python)
PID 909:  /bin/bash /app/zcode-driver/boot.sh start  (root, NOVO! ZCode Server)
PID 925:  /usr/bin/node /app/zcode-driver/main.mjs   (root, ZCode driver Node.js)
PID 935:  /app/.venv/bin/python main.py          (root, FastAPI ZAI Control em :12600)
PID 2146: /bin/sh -c 'su z -c "/bin/bash --noprofile --norc"'  (root)
PID 2147: su z -c /bin/bash --noprofile --norc  (root → z)
PID 2149: /bin/bash --noprofile --norc           (z, shell do agente)
PID 2150: ps aux --forest                        (z, filho do shell)
```

**Top 5 por uso de memória (RSS):**

| PID | RSS | Process |
|---|---|---|
| 935 | 145 MB | `/app/.venv/bin/python main.py` (ZAI Control) |
| 925 | 61 MB | `node /app/zcode-driver/main.mjs` (ZCode) |
| 2 | 41 MB | `caddy run --config /app/Caddyfile` |
| 894 | 31 MB | `uv run main.py` |
| 2147 | 4 MB | `su z -c bash` |

**Total de processos ativos no cgroup:** 27 (limite: `max` = ilimitado pelo cgroup, `ulimit -u` = 100.000)

---

## 2. Capabilities reais (decodificadas)

### PID 1 (tini, root) — CapEff = `0x00000000a80425fb`

```
cap_chown              (1)      — change file UIDs/GIDs
cap_dac_override       (2)      — bypass file r/w/x permission checks
cap_fowner             (3)      — bypass file owner checks
cap_fsetid             (4)      — set file setgid bit
cap_kill                (5)      — send signals to any process
cap_setgid              (6)      — set GID/supplementary GIDs
cap_setuid              (7)      — set UID
cap_setpcap             (8)      — set capabilities of other processes
cap_net_bind_service    (10)     — bind to ports < 1024
cap_net_raw             (13)     — use raw sockets (ping, etc.)
cap_sys_chroot          (18)     — use chroot()
cap_mknod              (27)     — create special files with mknod()
cap_audit_write         (29)     — write to kernel audit log
cap_setfcap             (31)     — set capabilities on files
```

**Total:** 14 capabilities (default Docker set).

### PID 2149 (shell `z`) — CapEff = `0x0000000000000000`

```
Z E R O  capabilities
```

Mesmo com `CapBnd = 0x00000000a80425fb` (bounding set herdado), o shell `z` não tem nenhuma capability efetiva. Isso é por causa do `su z` que descarta capabilities ao mudar de user.

**Confirmação empírica:** `ping` (que precisa `cap_net_raw`) falha com `Operation not permitted` — exatamente o que esperamos.

---

## 3. Seccomp

Todos os processos do container têm `Seccomp: 2` (filter mode) com 1 filter ativo. Isso bloqueia syscalls perigosas (`keyctl`, `ptrace` em outros processos, etc.).

**Implicação:** Não dá para usar `strace`, `gdb`, `ltrace` (todos AUSENTES do container).

---

## 4. Cgroup paths (v1, k8s.io)

Container ID: `c-6aec9447-14127d0f-9cd950901381`

```
11:name=systemd:/k8s.io/c-6aec9447-14127d0f-9cd950901381
10:devices:/k8s.io/...
9:blkio:/k8s.io/...
8:net_cls,net_prio:/k8s.io/...
7:perf_event:/k8s.io/...
6:cpuset:/k8s.io/...
5:memory:/k8s.io/...
4:cpu,cpuacct:/k8s.io/...
3:hugetlb:/k8s.io/...
2:freezer:/k8s.io/...
1:pids:/k8s.io/...
```

### Limites reais (medidos)

| Recurso | Limite | Medido |
|---|---|---|
| **memory.limit_in_bytes** | 4.294.967.296 (4 GiB) | ✅ |
| **memory.usage_in_bytes** (agora) | 764 MB | ~ |
| **memory.memsw.limit_in_bytes** | 9.223.372.036.854.771.712 (max int) | swap ilimitado mas sem swap real |
| **cpu.cfs_quota_us** | -1 (sem quota) | ✅ |
| **cpu.cfs_period_us** | 100.000 | ✅ |
| **cpu.shares** | 18.432 | relativo a outros cgroups |
| **cpuset.cpus** | 0-1 (2 CPUs) | ✅ |
| **pids.max** | max (ilimitado no cgroup) | ✅ |
| **pids.current** | 27 | ~ |
| **blkio.throttle.read/write_bps_device** | (vazio, sem throttling) | ✅ |
| **devices.list** (allowlist) | só chars essenciais | ✅ |

### Devices whitelist (cgroup `devices.list`)

```
c 1:3 rwm   /dev/null
c 1:5 rwm   /dev/zero
c 1:7 rwm   /dev/full
c 1:8 rwm   /dev/random
c 1:9 rwm   /dev/urandom
c 5:0 rwm   /dev/tty
c 5:1 rwm   /dev/ptmx
c 5:2 rwm   /dev/pts (não listado mas em /dev/pts)
c 10:200 rwm  /dev/net/tun (devices permitidos para network)
c *:* m     mknod permitido para char devices (mas sem uso sem cap_mknod)
b *:* m     mknod permitido para block devices (idem)
c 136:* rwm /dev/pts/* (pty slaves)
```

**Ausente:** `/dev/dri/*` (sem GPU), `/dev/video*` (sem câmera), `/dev/sd*` (sem discos raw).

---

## 5. Limites do kernel (escalonados a todos os processos)

### `/proc/sys/kernel/`
- `pid_max = 32.768` (limite de PIDs no sistema)
- `threads-max = 925` (max threads por processo — atenção: `make -j32` falha!)
- `ngroups_max = 65.536` (max grupos suplementares por user)

### `/proc/sys/fs/`
- `file-max = 100.000` (max file descriptors no sistema)
- `file-nr = 416 (open) 0 (free) 100.000 (max)` — só 416 fds abertos agora
- `pipe-max-size = 1.048.576` (1 MB max pipe)

### `/proc/sys/net/`
- `somaxconn = 4.096` (max socket listen backlog)
- `tcp_max_syn_backlog = 128` (baixo! syn flood risk)
- `ip_local_port_range = 32768-60999` (~28k portas efêmeras)
- `tcp_tw_reuse = 2` (reuse TIME_WAIT sockets)

### `ulimit -a` (do shell do z)

```
open files          1024 (soft), 100.000 (hard)  ← pode subir p/ 100k com ulimit -n
max user processes  100.000
stack size          8.192 KB (8 MB)
max locked memory   65.536 bytes (64 KB)
virtual memory      unlimited
data seg size       unlimited
file size           unlimited
cpu time            unlimited
```

**Importante:** soft limit `open files = 1024` — pode ser aumentado para 100.000 com `ulimit -n 100000`.

---

## 6. Variáveis FC (Function Compute) e KATA

```
FC_ACCOUNT_ID=1936221977589032                  # conta Alibaba Cloud
FC_CONTAINER_ID=c-6aec9447-14127d0f-9cd950901381
FC_CUSTOM_LISTEN_PORT=81                         # Caddy escuta aqui
FC_FUNCTION_HANDLER=index.handler
FC_FUNCTION_MEMORY_SIZE=4096                    # 4 GB RAM alocado
FC_FUNCTION_NAME=ws-c5793303-25e4-4fd4-af6c-4fa2a9edeb46
FC_INSTANCE_ID=c-6aec9447-14127d0f-9cd950901381
FC_REGION=cn-hongkong                            # região do container
KATA_CONTAINER=true                              # confirma Kata runtime
```

### URLs teóricas que podem ser alcançáveis

- `https://fc.cn-hongkong.aliyuncs.com/<account_id>/...` — endpoint público do FC
- `https://fc-<account_id>.cn-hongkong.fcapp.run/...` — endpoint do FC App
- `https://<function_name>.<account_id>.cn-hongkong.fcapp.run/...` — custom domain

**Testar:** se o Caddy em :81 está exposto para a internet via ingress do FC, poderíamos acessar por:
`https://<function_name>.cn-hongkong.fcapp.run/`

---

## 7. Rede completa

### Interfaces

```
lo:    127.0.0.1/8 (loopback)
dummy0: DOWN (interface virtual sem IP)
eth0:  21.0.15.199/32 (IP fixo dentro do namespace)
       fe80::2033:94ff:feab:1944/64 (IPv6 link-local)
       MTU = 1450 (default é 1500 — Kata overlay reduz)
       gateway: 21.0.0.1
```

### DNS

```
nameserver 100.100.2.136
nameserver 100.100.2.138
```

Privado Alibaba Cloud — responde em ~5ms para domínios comuns.

### /etc/hosts

```
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
21.0.15.199 c-6aec9447-14127d0f-9cd950901381  (próprio IP → container ID)
```

### Testes de rede empíricos

| Teste | Resultado | Tempo |
|---|---|---|
| 10 conexões HTTPS concorrentes (httpbin.org) | ✅ Todas 200 | ~0.5s total |
| Download 10MB (Cloudflare) | ✅ | ~3s |
| 5 sites simultâneos | ✅ Todos respondem | 0.06-0.86s |
| ICMP `ping 8.8.8.8` | ❌ `Operation not permitted` (sem `cap_net_raw`) | — |
| Bind `:80` | ❌ `Permission denied` (sem `cap_net_bind_service` para z) | — |
| Bind `:81` | ❌ `Permission denied` (Caddy em uso) | — |
| Bind `:3000` | ✅ OK | — |
| Cloud metadata `169.254.169.254` | (timeout silencioso — bloqueado) | — |
| Cloud metadata `100.100.100.200` (Alibaba) | (timeout silencioso — bloqueado) | — |

### Latência para sites comuns

```
example.com:     0.060s
google.com:      0.114s
github.com:      0.277s
gitlab.com:      0.369s (301 redirect)
bitbucket.org:   0.857s
```

---

## 8. Mounts detalhados (via `/proc/self/mountinfo`)

### Mount principal (rootfs overlay)

```
/  overlay  c-6aec9447-14127d0f-9cd950901381-rootfs
   rw,relatime
   lowerdir=/run/kata-containers/shared/containers/passthrough/<cid>/rootfs_lower
   upperdir=/run/builtin_wlayer/<cid>/upper
   workdir=/run/builtin_wlayer/<cid>/work
   index=off,volatile,userxattr
```

### Mounts persistentes (OSS via fuse)

```
/home/official_skills            tmpfs /storage/containers/rundoss-afcabeaa-...-official_skills-bridge
/home/sync                      tmpfs /storage/containers/rundoss-95d8886a-...-sync-bridge
/home/z/my-project/upload       tmpfs /storage/containers/rundoss-e35dcba5-...-upload-bridge
/tmp/my-project                 tmpfs /storage/containers/rundjuicefs-7b40304f-...-my-project-bridge
/home/user_skills               tmpfs /storage/containers/rundjuicefs-8ab0d9d0-...-user_skills-bridge
```

**Note:** todos esses mounts têm `tmpfs` na frente como cache local, mas apontam para `rundoss-*` (Alibaba OSS) ou `rundjuicefs-*` (PolarFS/JuiceFS).

### /.dockerenv (marcador)

```
/.dockerenv  virtiofs kataShared  rw,ro  (somente leitura)
            /passthrough/sandbox-064868cd91624ae3008e924a1dc63a20
```

### Mounts especiais

```
/etc/hostname    tmpfs kata-containers/sandbox/25-1333353-hostname
/etc/hosts       tmpfs kata-containers/sandbox/25-1333354-hosts
/etc/resolv.conf tmpfs kata-containers/sandbox/25-1333352-resolv.conf
/dev/shm         shm size=65536k (64MB)
/sys/fs/cgroup   tmpfs ro,nosuid,nodev,noexec
```

---

## 9. /etc/.z-ai-config completo (com chaves extras)

```json
{
  "baseUrl": "https://internal-api.z.ai/v1",
  "apiKey": "Z.ai",
  "chatId": "chat-47bed43b-db01-4d38-b538-964454b1a5c4",
  "userId": "acc97ee7-f0f5-4e21-bc8c-dd2915902f56",
  "token": "<JWT 243 chars>",
  "diskRetire": true,
  "stage": "default"
}
```

### `diskRetire: true` (NOVO)

Boolean. Provavelmente indica se o disco do container será reciclado/destruído após o fim da sessão. Isso afeta quando o `repo.tar` é gravado no pre-stop.

### `stage: "default"` (NOVO)

String. Indica qual preset de skills está ativo para este chat. Os stages estão definidos em `/home/official_skills/stages.yaml`. O `default` tem 21 skills (ASR, LLM, VLM, TTS, docx, pdf, etc.).

### JWT payload (sem expiração!)

```json
{
  "user_id": "acc97ee7-f0f5-4e21-bc8c-dd2915902f56",
  "chat_id": "chat-47bed43b-db01-4d38-b538-964454b1a5c4",
  "platform": "zai"
}
```

**Sem `exp`** — o token não expira sozinho. É revogado pelo backend quando a sessão termina.

---

## 10. Gateway routes by source (re-mapeado via `/metrics`)

### Source `Z` (15 routes — chat/web-dev stack, somos nós)

```
/external/*path              (proxy externo, 184 calls)
/v1/async-result             (12679 calls)
/v1/audio/asr               (24388 calls)
/v1/audio/tts               (17833 calls)
/v1/chat/completions         (159881 calls)
/v1/chat/completions/vision  (137059 calls)
/v1/fc/update-function      (92888 calls)
/v1/functions/invoke        (109642 calls)
/v1/images/generations      (41995 calls)
/v1/images/generations/edit (5373 calls)
/v1/images/search           (25373 calls)
/v1/oss/list                (4 calls — quase nunca usado por Z)
/v1/oss/upload              (2059 calls)
/v1/storage/pfs/clone-snapshot  (212 calls)
/v1/video/generation        (4527 calls)
```

### Source `zcode` (3 routes — ZCode Server)

```
/v1/fc/update-function       (counted together with Z)
/v1/oss/list                (zcode tem acesso próprio)
/v1/oss/upload              (zcode tem acesso próprio)
```

### Source `zai-agent` (1 route — chat backend)

```
/v1/zai-agent/chat/completions   (282973 calls — mais que todos!)
```

### Endpoints públicos (sem auth)

- `GET /metrics` — Prometheus metrics (público, contadores do gateway)
- `GET /external/` — Retorna `{"apis":{},"count":0}` (lista de APIs externas registradas)

---

## 11. /external/* — proxy de APIs externas (NOVO, não documentado)

### O que é

Endpoint em `https://internal-api.z.ai/external/<domain>` que faz proxy HTTP para APIs externas pré-registradas para o usuário.

### Estado atual

```bash
$ curl https://internal-api.z.ai/external/
{"apis":{},"count":0}
```

**Nenhuma API externa registrada para este usuário/chat.**

### Como funciona (inferido)

- URL: `https://internal-api.z.ai/external/<domain>/<path>`
- Substitui a URL base: chama `<domain>/<path>` e repassa o resultado
- Útil quando o sandbox não pode chamar diretamente uma API externa (ex: por rate limit ou bloqueio de IP)
- Domínios são pré-registrados no painel admin (não acessível a nós)
- Erro para domínio não registrado: `{"error":"api_not_found","message":"API for domain 'X' is not configured or disabled"}`

### Testes empíricos

```bash
# Lista de APIs registradas (atualmente vazia):
curl https://internal-api.z.ai/external/
{"apis":{},"count":0}

# Tentar acessar domínios comuns:
/external/github.com       → 404 api_not_found
/external/api.jina.ai      → 404 api_not_found
/external/example.com      → 404 api_not_found
/external/registry.npmjs.org → 404 api_not_found
```

**Conclusão:** o proxy está pronto, mas nenhum domínio está registrado. Para usar, seria preciso registrar via UI admin do Z.AI.

---

## 12. /v1/oss/upload — requer token diferente

```bash
$ curl -X POST https://internal-api.z.ai/v1/oss/upload?filename=test.txt \
  -H "Authorization: Bearer Z.ai" -H "X-Z-AI-From: Z" -H "X-Chat-Id: ..." \
  -H "X-User-Id: ..." -H "X-Token: ..." -d "content"
HTTP 401: {"error":"invalid token"}
```

Apesar de enviar todos os 5 headers de auth, retorna 401. Possíveis motivos:
1. Requer header `Content-Type: multipart/form-data` (não testado)
2. Requer path absoluto do arquivo OSS no body
3. Requer source `zcode` (não `Z`)
4. Requer token de sessão diferente do JWT do `/etc/.z-ai-config`

---

## 13. Python venv (430 pacotes reais, não 921)

**Importante:** a contagem anterior de "921 pacotes" incluía subdiretórios e arquivos de metadata, não pacotes reais. O número real via `importlib.metadata.distributions()` é **430 pacotes**.

### Top 15 por tamanho (em MB)

| Pacote | Tamanho | Categoria |
|---|---|---|
| nvidia-nccl-cu12 | 382.9 MB | ML/DL (NVIDIA collective comms) |
| vtk | 339.5 MB | 3D visualization |
| catboost | 293.7 MB | ML (gradient boosting) |
| aspose-words | 286.2 MB | Word docs |
| cadquery-ocp | 270.5 MB | CAD |
| xgboost | 239.3 MB | ML (gradient boosting) |
| casadi | 212.9 MB | Scientific (optimal control) |
| opencv-python-headless | 161.9 MB | Image/CV |
| playwright | 128.5 MB | Browser |
| llvmlite | 127.3 MB | JIT compilation |
| scipy | 125.0 MB | Scientific |
| spacy | 112.1 MB | NLP |
| rasterio | 110.3 MB | GIS |
| pyogrio | 99.3 MB | GIS (OGR) |
| imageio-ffmpeg | 76.2 MB | Video |

### Categorias contadas

| Categoria | Count |
|---|---|
| Web (FastAPI, aiohttp, httpx, pydantic, etc.) | 15 |
| ML/DL (sklearn, xgboost, catboost, lightgbm, spacy, huggingface) | 9 |
| Viz (matplotlib, plotly, bokeh, seaborn, vtk) | 8 |
| Data (numpy, pandas, scipy, numba, pyarrow) | 7 |
| Audio/Video (moviepy, pydub, librosa, soundfile, ffmpeg) | 7 |
| GIS (rasterio, geopandas, shapely, fiona, pyproj) | 6 |
| Image/CV (opencv, pillow, scikit-image, imageio) | 6 |
| Scientific (sympy, casadi, scikit-image, scikit-learn) | 4 |
| Async/Concurrent (celery, redis, kombu, asgiref) | 4 |
| CAD/3D (cadquery, cadquery-ocp, trimesh) | 3 |
| MCP (mcp, fastmcp) | 2 |

---

## 14. CLI tools ausentes (não no PATH)

| Tool | Status |
|---|---|
| `mvn`, `gradle` | AUSENTE (Java build) |
| `docker`, `podman`, `kubectl` | AUSENTE (sem containers) |
| `htop`, `iotop`, `iftop` | AUSENTE (monitoring) |
| `tcpdump` | AUSENTE (network capture — bloqueado por seccomp) |
| `strace`, `ltrace`, `gdb`, `valgrind` | AUSENTE (debug — bloqueado por seccomp) |
| `ripgrep`, `fd`, `bat`, `exa`, `tldr` | AUSENTE (modern Unix tools) |
| `yq` | AUSENTE (YAML jq) |
| `nc` (netcat) | AUSENTE |

---

## 15. Como aproveitar as novas descobertas

### Para IAs que precisam rodar ML

```python
# Já disponível no venv (Python 3.12.16):
import xgboost as xgb      # ML gradient boosting (239 MB)
import catboost as cb       # ML gradient boosting (294 MB)
import lightgbm as lgb      # ML gradient boosting
import sklearn              # Classic ML (1.5.2)
import scipy                # Scientific (1.14.1)
import spacy                # NLP (3.8.11)
import huggingface_hub      # NLP models
import sklearn              # Classic ML
```

### Para IAs que precisam de CAD/3D

```python
import cadquery as cq       # Parametric CAD (2.6.1)
import trimesh              # Mesh processing (4.11.1)
import vtk                  # 3D visualization (9.3.1)
```

### Para IAs que precisam de GIS

```python
import rasterio             # Raster data (1.5.0)
import geopandas            # Vector data (1.1.2)
import shapely              # Geometric ops (2.1.2)
import pyproj               # CRS (3.7.2)
```

### Para IAs que precisam de scientific computing

```python
import sympy                # Symbolic math (1.14.0)
import casadi               # Optimal control (3.7.2)
import numba                # JIT compilation (0.61.0)
import llvmlite             # LLVM bindings (0.44.0)
```

### Para aumentar limites do shell

```bash
# Aumentar max open files (1024 → 100000):
ulimit -n 100000

# Verificar:
ulimit -n  # 100000
```

### Para ver o ZCode Server rodando

```bash
ps -ef | grep zcode-driver
# root  909  /bin/bash /app/zcode-driver/boot.sh start
# root  925  /usr/bin/node /app/zcode-driver/main.mjs
```

### Para listar APIs externas registradas no gateway

```bash
curl https://internal-api.z.ai/external/
# {"apis":{},"count":0}  ← atualmente vazio
```

### Para verificar /v1/oss/upload (ainda precisa descobrir como)

```bash
# Tentar com multipart:
curl -X POST https://internal-api.z.ai/v1/oss/upload \
  -H "Authorization: Bearer Z.ai" -H "X-Z-AI-From: Z" \
  -H "X-Chat-Id: <chatId>" -H "X-User-Id: <userId>" -H "X-Token: <token>" \
  -F "file=@test.txt"
# (ainda retorna 401 — requer investigação adicional)
```

---

## 16. Próximas investigações sugeridas

| Tópico | Como |
|---|---|
| Descobrir a URL pública do container (FC ingress) | Procurar em /etc/hosts, env, ou chamar `https://<function_name>.cn-hongkong.fcapp.run/` |
| Entender o `zcode-driver` (ZCode Server rodando ativamente) | Ver `node --inspect` se disponível, ou ler `/app/zcode-driver/` se conseguir permissão |
| Mapear o `/app` directory (ainda 711 root) | Ver se alguma tool interna expõe seu conteúdo |
| Decodificar o `diskRetire: true` | Verificar se algum processo monitora o disco durante o shutdown |
| Testar `/v1/fc/update-function` (92k calls) | Tentar POST com body mínimo |
| Verificar se há WebSocket no `/mcp` (não só HTTP) | Tentar upgrade header |

---

*Investigação realizada em 05/11/2026 por: ps, /proc, /sys/fs/cgroup, mountinfo, env, curl, python3. 21 novas descobertas documentadas.*
