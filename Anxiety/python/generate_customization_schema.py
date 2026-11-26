#!/usr/bin/env python3
"""Regenerate the Lua schema from Locale usages and the bundled Nebula theme."""

import argparse
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "lua" / "customization_schema.lua"

LUA_TOKENS = re.compile(
    r"--\[(?P<comment_level>=*)\[.*?\](?P=comment_level)\]"
    r"|--[^\n]*"
    r"|\[(?P<string_level>=*)\[.*?\](?P=string_level)\]"
    r"""|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'"""
    r"|[A-Za-z_][A-Za-z_0-9]*|[^\s]",
    re.DOTALL,
)
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
COLOR_FIELDS = {"Background", "Color", "EmptyColor", "EndColor", "FontColor", "LineColor"}

READ_REFERENCES = r"""
local root = arg[1]
local json = dofile(root .. "/lua/json.lua")
local customization = dofile(root .. "/lua/customization.lua")

local function read(file, name)
    local value, err = customization.read(root .. "/" .. file, name)
    assert(type(value) == "table", err or file .. ": expected a " .. name .. " table")
    return value
end

local function types(value)
    if type(value) ~= "table" then
        return type(value)
    end
    local result = {}
    for key, item in pairs(value) do
        assert(type(key) == "string", "reference keys must be strings")
        result[key] = types(item)
    end
    return result
end

io.write(json.stringify({
    theme = types(read("themes/theme_nebula.lua", "Theme")),
    en = types(read("language/en.lua", "Locale")),
    de = types(read("language/de.lua", "Locale"))
}))
"""


def locale_keys():
    keys = set()
    for path in sorted((ROOT / "lua").rglob("*.lua")):
        if path == SCHEMA:
            continue
        source = path.read_text(encoding="utf-8")
        tokens = [match for match in LUA_TOKENS.finditer(source) if not match[0].startswith("--")]
        for index, token in enumerate(tokens):
            if token[0] != "Locale" or (index and tokens[index - 1][0] in (".", ":")):
                continue
            following = [match[0] for match in tokens[index + 1:index + 4]]
            if len(following) >= 2 and following[0] == "." and IDENTIFIER.fullmatch(following[1]):
                keys.add(following[1])
            elif following[:1] == ["["]:
                if len(following) == 3 and following[2] == "]":
                    key = re.fullmatch(r"""(["'])([A-Za-z_][A-Za-z_0-9]*)\1""", following[1])
                    if key:
                        keys.add(key[2])
                        continue
                line = source.count("\n", 0, token.start()) + 1
                raise ValueError(f"{path}:{line}: use a literal Locale key so it can be validated")
    if not keys:
        raise ValueError("No Locale fields found in lua/")
    return {key: "string" for key in sorted(keys)}


def read_references(lua_executable):
    with tempfile.TemporaryDirectory() as directory:
        script = Path(directory) / "read_references.lua"
        script.write_text(READ_REFERENCES, encoding="utf-8")
        result = subprocess.run(
            [lua_executable, str(script), str(ROOT)],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    return json.loads(result.stdout)


def theme_schema(fields, path=()):
    result = {}
    for key, value in fields.items():
        if isinstance(value, dict):
            result[key] = theme_schema(value, path + (key,))
        elif value == "string" and (key in COLOR_FIELDS or path == ("Colors",)):
            result[key] = "color"
        elif value in {"string", "number", "boolean"}:
            result[key] = value
        else:
            raise ValueError(f"Unsupported theme field type at {'.'.join(path + (key,))}: {value}")
    return result


def lua_table(fields, depth=0):
    indent = "    " * depth
    lines = ["{"]
    for key, value in sorted(fields.items()):
        name = f"[{json.dumps(key, ensure_ascii=False)}]"
        rendered = lua_table(value, depth + 1) if isinstance(value, dict) else json.dumps(value)
        lines.append(f"{indent}    {name} = {rendered},")
    lines.append(indent + "}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", help="Lua 5.3+ executable used at generation time")
    parser.add_argument("--check", action="store_true", help="Check whether the tracked schema is current")
    args = parser.parse_args()
    executable = args.lua or next(
        (path for name in ("lua", "lua5.4", "lua5.3", "texlua") if (path := shutil.which(name))),
        None,
    )
    if not executable:
        parser.error("Lua 5.3+ is required to evaluate the reference files (or pass --lua)")

    try:
        language = locale_keys()
        references = read_references(executable)
        for locale in ("en", "de"):
            missing = [key for key in language if references[locale].get(key) != "string"]
            if missing:
                raise ValueError(f"language/{locale}.lua: missing string fields: {', '.join(missing)}")
        schema = {"language": language, "theme": theme_schema(references["theme"])}
        output = "-- Generated by python/generate_customization_schema.py.\nreturn " + lua_table(schema) + "\n"
        if args.check:
            if not SCHEMA.is_file() or SCHEMA.read_text(encoding="utf-8") != output:
                raise ValueError(f"{SCHEMA.name} is outdated. Run this script without --check.")
        else:
            SCHEMA.write_text(output, encoding="utf-8")
    except subprocess.CalledProcessError as error:
        parser.exit(1, f"{error.stderr.strip() or error.stdout.strip() or error}\n")
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
