#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListResourcesRequestSchema, ListToolsRequestSchema, ReadResourceRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import fs from "node:fs/promises";
import path from "node:path";
import YAML from "yaml";

const token = process.env.SUPERVISOR_TOKEN || process.env.HA_ACCESS_TOKEN || "";
const apiBase = process.env.SUPERVISOR_TOKEN ? "http://supervisor/core/api" : "http://supervisor/core/api";
const configRoot = "/homeassistant";

async function ha(pathname, options = {}) {
  if (!token) throw new Error("SUPERVISOR_TOKEN/HA_ACCESS_TOKEN not available");
  const res = await fetch(`${apiBase}${pathname}`, {
    ...options,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", ...(options.headers || {}) }
  });
  const text = await res.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!res.ok) throw new Error(`HA API ${res.status}: ${typeof body === 'string' ? body : JSON.stringify(body)}`);
  return body;
}
function safePath(rel) {
  const full = path.resolve(configRoot, rel || ".");
  if (!full.startsWith(configRoot)) throw new Error("Path escapes /homeassistant");
  if (full.includes("/.storage/")) throw new Error("Refusing to write .storage via MCP");
  return full;
}
const server = new Server({ name: "homeassistant-codex", version: "0.1.0" }, { capabilities: { tools: {}, resources: {} } });

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: [
  { name: "get_states", description: "Get Home Assistant entity states; optionally filter by domain or entity_id.", inputSchema: { type: "object", properties: { domain: { type: "string" }, entity_id: { type: "string" } } } },
  { name: "get_services", description: "List Home Assistant services, optionally by domain.", inputSchema: { type: "object", properties: { domain: { type: "string" } } } },
  { name: "call_service", description: "Call a Home Assistant service.", inputSchema: { type: "object", required: ["domain", "service"], properties: { domain: { type: "string" }, service: { type: "string" }, service_data: { type: "object" } } } },
  { name: "get_error_log", description: "Get Home Assistant error log.", inputSchema: { type: "object", properties: {} } },
  { name: "render_template", description: "Render a Home Assistant Jinja template.", inputSchema: { type: "object", required: ["template"], properties: { template: { type: "string" } } } },
  { name: "read_config_file", description: "Read a file under /homeassistant.", inputSchema: { type: "object", required: ["path"], properties: { path: { type: "string" } } } },
  { name: "write_config_safe", description: "Write YAML/text under /homeassistant with backup, YAML parse, and basic content-loss protection.", inputSchema: { type: "object", required: ["path", "content"], properties: { path: { type: "string" }, content: { type: "string" }, confirm_deletions: { type: "boolean" }, dry_run: { type: "boolean" } } } },
  { name: "validate_yaml", description: "Parse YAML content and report errors.", inputSchema: { type: "object", required: ["content"], properties: { content: { type: "string" } } } },
  { name: "hab_run", description: "Run hab CLI command. Example args: ['entity','list','--domain','light'].", inputSchema: { type: "object", required: ["args"], properties: { args: { type: "array", items: { type: "string" } } } } }
]}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const a = req.params.arguments || {};
  try {
    switch (req.params.name) {
      case "get_states": {
        let states = await ha("/states");
        if (a.entity_id) states = states.filter(s => s.entity_id === a.entity_id);
        if (a.domain) states = states.filter(s => s.entity_id?.startsWith(`${a.domain}.`));
        return { content: [{ type: "text", text: JSON.stringify(states, null, 2) }] };
      }
      case "get_services": {
        const services = await ha("/services");
        const out = a.domain ? services.filter(s => s.domain === a.domain) : services;
        return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
      }
      case "call_service": {
        const result = await ha(`/services/${a.domain}/${a.service}`, { method: "POST", body: JSON.stringify(a.service_data || {}) });
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case "get_error_log": return { content: [{ type: "text", text: await ha("/error_log") }] };
      case "render_template": {
        const result = await ha("/template", { method: "POST", body: JSON.stringify({ template: a.template }) });
        return { content: [{ type: "text", text: typeof result === "string" ? result : JSON.stringify(result, null, 2) }] };
      }
      case "read_config_file": {
        const txt = await fs.readFile(safePath(a.path), "utf8");
        return { content: [{ type: "text", text: txt }] };
      }
      case "validate_yaml": {
        YAML.parse(a.content);
        return { content: [{ type: "text", text: "YAML parsed successfully." }] };
      }
      case "write_config_safe": {
        const target = safePath(a.path);
        const existing = await fs.readFile(target, "utf8").catch(() => "");
        if (/\.ya?ml$/i.test(target)) YAML.parse(a.content);
        if (!a.confirm_deletions && existing) {
          const oldLines = existing.split(/\r?\n/).length;
          const newLines = a.content.split(/\r?\n/).length;
          if (newLines < oldLines * 0.5) throw new Error("Refusing significant file shrink without confirm_deletions=true");
        }
        if (a.dry_run) return { content: [{ type: "text", text: "Dry run OK. No file written." }] };
        await fs.mkdir(path.dirname(target), { recursive: true });
        if (existing) await fs.writeFile(`${target}.bak`, existing);
        await fs.writeFile(target, a.content);
        return { content: [{ type: "text", text: `Wrote ${target}${existing ? ` and backup ${target}.bak` : ""}` }] };
      }
      case "hab_run": {
        const { spawn } = await import("node:child_process");
        const args = Array.isArray(a.args) ? a.args : [];
        const out = await new Promise((resolve, reject) => {
          const p = spawn("hab", args, { cwd: configRoot, env: process.env });
          let stdout="", stderr="";
          p.stdout.on("data", d => stdout += d);
          p.stderr.on("data", d => stderr += d);
          p.on("close", code => code === 0 ? resolve(stdout || stderr) : reject(new Error(stderr || `hab exited ${code}`)));
        });
        return { content: [{ type: "text", text: out }] };
      }
      default: throw new Error(`Unknown tool: ${req.params.name}`);
    }
  } catch (e) { return { isError: true, content: [{ type: "text", text: String(e?.message || e) }] }; }
});

server.setRequestHandler(ListResourcesRequestSchema, async () => ({ resources: [
  { uri: "ha://states/summary", name: "Entity state summary", mimeType: "text/markdown" },
  { uri: "ha://config/files", name: "Top-level Home Assistant config files", mimeType: "application/json" }
]}));
server.setRequestHandler(ReadResourceRequestSchema, async (req) => {
  if (req.params.uri === "ha://states/summary") {
    const states = await ha("/states");
    const byDomain = states.reduce((m, s) => { const d = s.entity_id.split('.')[0]; m[d]=(m[d]||0)+1; return m; }, {});
    return { contents: [{ uri: req.params.uri, mimeType: "text/markdown", text: Object.entries(byDomain).map(([d,c])=>`- ${d}: ${c}`).join("\n") }] };
  }
  if (req.params.uri === "ha://config/files") {
    const entries = await fs.readdir(configRoot, { withFileTypes: true });
    return { contents: [{ uri: req.params.uri, mimeType: "application/json", text: JSON.stringify(entries.filter(e=>e.isFile()).map(e=>e.name), null, 2) }] };
  }
  throw new Error("Unknown resource");
});

await server.connect(new StdioServerTransport());
