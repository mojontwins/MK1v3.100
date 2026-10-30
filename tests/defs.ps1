# Ayudante de tests\build.bat: aplica a una copia de src\ las opciones de la
# linea de comandos, lo mismo que hace build.sh con sed.
#
# Uso: defs.ps1 COPIA_DE_SRC zx|cpc SALIDA.bin [DEF[=valor] ...] [-UNDEF ...] [@script.spt]
#   DEF        activa (o anade) "#define DEF valor" en config.h
#   -UNDEF     comenta "#define UNDEF"
#   @archivo   usa ese script (src\script\script.spt) y activa ACTIVATE_SCRIPTING;
#              si junto al script hay un extern.h, se usa tambien
# Los dos primeros argumentos tras COPIA_DE_SRC (plataforma y salida) se ignoran:
# build.bat pasa su linea de comandos entera.

$src = $args[0]
$cfg = Join-Path $src 'dev\config.h'
$text = [IO.File]::ReadAllText($cfg)
$extra = ''

# Sustituye solo la primera coincidencia, con el texto tal cual (sin $1...)
function ReplaceFirst ([string] $s, [string] $pattern, [scriptblock] $repl) {
	$re = New-Object Text.RegularExpressions.Regex ($pattern, 'Multiline')
	return $re.Replace($s, [Text.RegularExpressions.MatchEvaluator] $repl, 1)
}

for ($i = 3; $i -lt $args.Count; $i++) {
	$d = [string] $args[$i]
	if ($d -eq '') { continue }

	if ($d.StartsWith('@')) {
		$spt = $d.Substring(1)
		New-Item -ItemType Directory -Force (Join-Path $src 'script') | Out-Null
		Copy-Item $spt (Join-Path $src 'script\script.spt')
		$x = Join-Path (Split-Path -Parent $spt) 'extern.h'
		if (Test-Path $x) { Copy-Item $x (Join-Path $src 'dev\extern.h') }
		$text = [regex]::Replace($text, '(?m)^[ \t]*//[ \t]*#define[ \t]+ACTIVATE_SCRIPTING\b', '#define ACTIVATE_SCRIPTING')
		continue
	}

	if ($d.StartsWith('-')) {
		$u = [regex]::Escape($d.Substring(1))
		$text = [regex]::Replace($text, "(?m)^([ \t]*)#define[ \t]+$u\b", { param($m) $m.Groups[1].Value + '//#define ' + $d.Substring(1) })
		continue
	}

	$hasValue = $d.Contains('=')
	if ($hasValue) { $k = $d.Substring(0, $d.IndexOf('=')); $v = $d.Substring($d.IndexOf('=') + 1) }
	else { $k = $d; $v = '' }
	$ke = [regex]::Escape($k)

	if ($text -match "(?m)^[ \t]*//[ \t]*#define[ \t]+$ke\b") {
		$text = ReplaceFirst $text "^[ \t]*//[ \t]*#define[ \t]+$ke\b[^\r\n]*" { "#define $k $v" }
	} elseif ($text -match "(?m)^[ \t]*#define[ \t]+$ke\b") {
		# Ya activo: se cambia el valor si se ha dado uno
		if ($hasValue) {
			$text = ReplaceFirst $text "^([ \t]*)#define[ \t]+$ke\b[^/\r\n]*" { param($m) $m.Groups[1].Value + "#define $k $v`t" }
		}
	} else {
		$extra += "#define $k $v`n"
	}
}

[IO.File]::WriteAllText($cfg, $extra + $text)
