#!/usr/bin/env node

import { readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const DEFAULT_ENDPOINT = 'https://mcp.svelte.dev/mcp';

function usage(exitCode = 0) {
	const out = exitCode === 0 ? process.stdout : process.stderr;
	out.write(`Usage: svelte-autofix.mjs [options] <file.svelte>

Options:
  --version <value>   Desired Svelte version, default: 5
  --async             Mark component/module as async
  --json              Print raw normalized JSON
  --strict            Exit nonzero when issues or suggestions are returned
  --endpoint <url>    MCP endpoint, default: ${DEFAULT_ENDPOINT}
  -h, --help          Show this help
`);
	process.exit(exitCode);
}

function parseArgs(argv) {
	const opts = {
		version: 5,
		async: false,
		json: false,
		strict: false,
		endpoint: DEFAULT_ENDPOINT,
		file: null
	};

	for (let i = 0; i < argv.length; i += 1) {
		const arg = argv[i];
		if (arg === '-h' || arg === '--help') usage(0);
		if (arg === '--async') {
			opts.async = true;
			continue;
		}
		if (arg === '--json') {
			opts.json = true;
			continue;
		}
		if (arg === '--strict') {
			opts.strict = true;
			continue;
		}
		if (arg === '--version') {
			opts.version = argv[++i];
			if (!opts.version) throw new Error('--version requires a value');
			continue;
		}
		if (arg === '--endpoint') {
			opts.endpoint = argv[++i];
			if (!opts.endpoint) throw new Error('--endpoint requires a value');
			continue;
		}
		if (arg.startsWith('-')) throw new Error(`Unknown option: ${arg}`);
		if (opts.file) throw new Error(`Unexpected extra argument: ${arg}`);
		opts.file = arg;
	}

	if (!opts.file) usage(2);
	return opts;
}

function parseSse(text) {
	const messages = [];
	for (const block of text.split(/\r?\n\r?\n/)) {
		const dataLines = [];
		for (const line of block.split(/\r?\n/)) {
			if (line.startsWith('data:')) dataLines.push(line.slice(5).trimStart());
		}
		if (dataLines.length === 0) continue;
		const data = dataLines.join('\n');
		if (data === '[DONE]') continue;
		messages.push(JSON.parse(data));
	}
	return messages;
}

async function postJson(endpoint, body, sessionId = null) {
	const headers = {
		accept: 'application/json, text/event-stream',
		'content-type': 'application/json'
	};
	if (sessionId) headers['mcp-session-id'] = sessionId;

	const res = await fetch(endpoint, {
		method: 'POST',
		headers,
		body: JSON.stringify(body)
	});

	const text = await res.text();
	if (!res.ok && res.status !== 202) {
		throw new Error(`MCP HTTP ${res.status}: ${text}`);
	}

	return {
		status: res.status,
		sessionId: res.headers.get('mcp-session-id') ?? sessionId,
		messages: text ? parseSse(text) : []
	};
}

function responseById(messages, id) {
	const message = messages.find((entry) => entry.id === id);
	if (!message) throw new Error(`MCP response id ${id} not found`);
	if (message.error) {
		throw new Error(`MCP error ${message.error.code}: ${message.error.message}`);
	}
	return message.result;
}

function normalizeToolResult(result) {
	if (result?.structuredContent) return result.structuredContent;

	const text = result?.content?.find((item) => item.type === 'text')?.text;
	if (text) {
		try {
			return JSON.parse(text);
		} catch {
			return { text };
		}
	}

	return result;
}

function printHuman(payload) {
	const issues = payload.issues ?? [];
	const suggestions = payload.suggestions ?? [];
	const needsAnotherPass = Boolean(payload.require_another_tool_call_after_fixing);

	console.log('Svelte autofixer report');
	console.log('');
	console.log(`issues: ${issues.length}`);
	for (const issue of issues) console.log(`- ${issue}`);
	console.log('');
	console.log(`suggestions: ${suggestions.length}`);
	for (const suggestion of suggestions) console.log(`- ${suggestion}`);
	console.log('');
	console.log(`another pass required: ${needsAnotherPass ? 'yes' : 'no'}`);
}

async function run() {
	const opts = parseArgs(process.argv.slice(2));
	const filePath = path.resolve(opts.file);
	if (!filePath.endsWith('.svelte') && !filePath.endsWith('.svelte.ts')) {
		throw new Error('Expected a .svelte or .svelte.ts file');
	}

	const code = await readFile(filePath, 'utf8');

	const initialized = await postJson(opts.endpoint, {
		jsonrpc: '2.0',
		id: 1,
		method: 'initialize',
		params: {
			protocolVersion: '2025-03-26',
			capabilities: {},
			clientInfo: {
				name: 'svelte-autofix-agent-script',
				version: '1.0.0'
			}
		}
	});

	const sessionId = initialized.sessionId;
	if (!sessionId) throw new Error('MCP server did not return mcp-session-id');
	responseById(initialized.messages, 1);

	await postJson(
		opts.endpoint,
		{
			jsonrpc: '2.0',
			method: 'notifications/initialized',
			params: {}
		},
		sessionId
	);

	const args = {
		code,
		desired_svelte_version: opts.version,
		filename: path.basename(filePath)
	};
	if (opts.async) args.async = true;

	const called = await postJson(
		opts.endpoint,
		{
			jsonrpc: '2.0',
			id: 2,
			method: 'tools/call',
			params: {
				name: 'svelte-autofixer',
				arguments: args
			}
		},
		sessionId
	);

	const payload = normalizeToolResult(responseById(called.messages, 2));

	if (opts.json) {
		console.log(JSON.stringify(payload, null, 2));
	} else {
		printHuman(payload);
	}

	const issueCount = payload.issues?.length ?? 0;
	const suggestionCount = payload.suggestions?.length ?? 0;
	if (opts.strict && (issueCount > 0 || suggestionCount > 0)) {
		process.exitCode = 1;
	}
}

run().catch((error) => {
	console.error(`svelte-autofix: ${error.message}`);
	process.exit(1);
});
