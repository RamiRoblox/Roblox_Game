#!/usr/bin/env bash
# Hook PreToolUse de Claude Code (Bash y PowerShell): bloquea cualquier `git push`
# mientras la rama actual sea `main`, aunque el comando no nombre `main`
# (por ejemplo, un `git push` a secas). Complementa los `deny` de settings.json.
# - Si bloquea: mensaje en stderr y sale con 2 → Claude no ejecuta el comando y ve el motivo.
# - Si no hay push, no es un repo o la rama no es main: sale con 0.
# Corre en Git Bash (Windows) y en bash (Mac/Linux). No necesita jq ni Node.

input="$(cat)"

# ¿El comando tiene un `git push`? (también `git -C dir push`, `git -c x=y push`)
if ! printf '%s' "$input" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[[:alnum:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+push([^[:alnum:]_-]|$)'; then
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
