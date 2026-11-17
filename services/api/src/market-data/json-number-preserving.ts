const JSON_NUMBER_TOKEN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/y;
/** Parses provider JSON while preserving every numeric token as its exact source string. */
export function parseJsonPreservingNumbers(source: string): unknown {
  if (typeof source !== "string") throw new TypeError("JSON source must be a string.");
  let output = "";
  let inString = false;
  let escaped = false;
  for (let index = 0; index < source.length;) {
    const character = source[index];
    if (inString) {
      output += character;
      if (escaped) escaped = false;
      else if (character === "\\") escaped = true;
      else if (character === '"') inString = false;
      index += 1;
      continue;
    }
    if (character === '"') { inString = true; output += character; index += 1; continue; }
    if (character === "-" || (character >= "0" && character <= "9")) {
      JSON_NUMBER_TOKEN.lastIndex = index;
      const match = JSON_NUMBER_TOKEN.exec(source);
      if (!match) throw new SyntaxError("Provider JSON contains an invalid numeric token.");
      output += JSON.stringify(match[0]);
      index += match[0].length;
      continue;
    }
    output += character;
    index += 1;
  }
  return JSON.parse(output);
}
