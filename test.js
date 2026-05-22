const fs = require('fs');

let oc = {
  mcp: {
    stripe: { command: "npx", args: ["stripe"], environment: { STRIPE_KEY: "sk_test_123" } },
    docker: { command: "docker", args: ["run"] }
  }
};

let toml = '';
Object.entries(oc.mcp).forEach(([k, v]) => {
  const cmd = Array.isArray(v.command) ? v.command : [v.command];
  toml += '\n[mcp_servers.' + k + ']\n';
  toml += 'command = "' + cmd[0] + '"\n';
  if (cmd.length > 1) toml += 'args = [' + cmd.slice(1).map(a => '"' + a + '"').join(', ') + ']\n';
  if (v.environment && Object.keys(v.environment).length) {
    toml += '\n[mcp_servers.' + k + '.env]\n';
    Object.entries(v.environment).forEach(([ek, ev]) => {
      toml += ek + ' = "' + ev + '"\n';
    });
  }
});

console.log("--- GENERATED TOML ---");
console.log(toml);

// Now the uninstall logic
const keys = Object.keys(oc.mcp);
keys.forEach(k => {
  const lines = toml.split('\n');
  let out = [];
  let skip = false;
  for (const line of lines) {
    const m = line.match(/^\[([^\]]+)\]/);
    if (m) {
      if (m[1] === 'mcp_servers.' + k || m[1].startsWith('mcp_servers.' + k + '.')) skip = true;
      else skip = false;
    }
    if (!skip) out.push(line);
  }
  toml = out.join('\n');
});

console.log("--- STRIPPED TOML ---");
console.log(toml.replace(/\n{3,}/g, '\n\n').trimEnd() + '\n');
