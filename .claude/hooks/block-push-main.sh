#!/usr/bin/env bash
# Hook PreToolUse de Claude Code (Bash y PowerShell): bloquea cualquier `git push`
# mientras la rama actual sea `main`, aunque el comando no nombre `main`
# (por ejemplo, un `git push` a secas). Complementa los `deny` de settings.json.
# - Si bloquea: mensaje en stderr y sale con 2 → Claude no ejecuta el comando y ve el motivo.
# - Si no hay push, no es un repo o la rama no es main: sale con 0.
# Corre en Git Bash (Windows) y en bash (Mac/Linux). No necesita jq ni Node.

input="$(cat)"

# Sacar solo el valor de "command" del JSON (así no se frena por un "git push" que aparece
# en otro campo). Si no hay comando, no hay nada que bloquear.
cmd="$(printf '%s' "$input" \
	| grep -Eo '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
	| head -n 1 \
	| sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"
[ -n "$cmd" ] || exit 0

# ¿Hay un `git push` que se EJECUTA? Tiene que estar al principio del comando o después de
# ; & | ( ` (o un salto de línea), o dentro de `bash -c "..."` / `pwsh -Command "..."`.
# Así `echo "git push"` o un mensaje de commit que nombra "git push" no se bloquean.
# También se detecta `git -C dir push` y `git -c x=y push`.
sep='(^|[;&|(`]|\\n|(-c|-Command)[[:space:]]+\\?[^[:alnum:][:space:]])'
push='[[:space:]]*git([[:space:]]+-[[:alnum:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+push([^[:alnum:]_-]|$)'
if ! printf '%s' "$cmd" | grep -Eq "${sep}${push}"; then
	exit 0
fi

dir="${CLAUDE_PROJECT_DIR:-.}"
branch="$(git -C "$dir" branch --show-current 2>/dev/null)"

if [ "$branch" = "main" ]; then
	printf '%s\n' \
		"No se puede hacer git push estando en main (regla del proyecto, ver CLAUDE.md)." \
		"Creá una rama (git switch -c feature/<nombre> o fix/<nombre>), pusheá esa y abrí un PR." >&2
	exit 2
fi

exit 0
