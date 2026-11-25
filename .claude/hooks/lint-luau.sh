#!/usr/bin/env bash
# Hook PostToolUse de Claude Code: después de editar/crear un .luau,
# formatea con StyLua y después lintea con Selene.
# - Si Selene (o StyLua) reporta errores: los imprime en stderr y sale con 2 → Claude los ve.
# - Si el archivo no es .luau o las herramientas no están instaladas: sale con 0 sin hacer nada.
# Corre en Git Bash (Windows) y en bash/sh (Mac/Linux). No necesita jq ni Node.

input="$(cat)"

# Extraer tool_input.file_path del JSON (las barras invertidas de Windows vienen escapadas: \\)
file="$(printf '%s' "$input" \
	| grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
	| head -n 1 \
	| sed -E 's/^"file_path"[[:space:]]*:[[:space:]]*"(.*)"$/\1/' \
	| sed 's/\\\\/\//g')"

case "$file" in
	*.luau | *.lua) ;;
	*) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# Correr desde la raíz del proyecto para que tomen stylua.toml / selene.toml
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

# Rokit puede no estar en el PATH de la sesión (por ejemplo, recién instalado)
export PATH="$HOME/.rokit/bin:$PATH"

# Devuelve 0 si la herramienta existe y funciona (los shims de Rokit fallan si falta `rokit install`)
tool_ok() {
	command -v "$1" >/dev/null 2>&1 && "$1" --version >/dev/null 2>&1
}

report=""

if tool_ok stylua; then
	if ! out="$(stylua "$file" 2>&1)"; then
		report="${report}[StyLua] No se pudo formatear ${file}:
${out}
"
	fi
fi

if tool_ok selene; then
	# Formato completo (no "quiet") para que se vea el mensaje de la regla, p. ej. "Usá task.wait ..."
	if ! out="$(selene --no-summary "$file" 2>&1)"; then
		report="${report}[Selene] Problemas en ${file}:
${out}
"
	fi
fi

if [ -n "$report" ]; then
	printf '%s\nArreglá estos problemas antes de seguir.\n' "$report" >&2
	exit 2
fi

exit 0
