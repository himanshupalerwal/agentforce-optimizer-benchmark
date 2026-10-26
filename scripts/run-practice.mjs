// Runs the 60 practice conversations against the published agent, one session
// each, so they land in the org's session tracing for Agent Optimizer to read.
//
//   node scripts/run-practice.mjs <target-org> [first-id] [last-id]
//   (or: npm run practice -- <target-org>)
//
// Turn on session tracing first (Setup, Einstein Audit, Analytics, and
// Monitoring Setup), or the sessions leave no record for Optimizer.
//
// Each transcript is saved under practice/runs/<date>/<id>.json. The script
// refuses to send anything if a practice line overlaps the test set: the test
// questions must never reach Optimizer.
import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT, parseCsv } from './lib.mjs';
import { AGENT } from './build-test-spec.mjs';

const [org, firstId = 'PR-01', lastId = 'PR-60'] = process.argv.slice(2);
if (!org) {
  console.error('usage: node scripts/run-practice.mjs <target-org> [first-id] [last-id]');
  process.exit(2);
}

// Guard: the consistency check covers overlap; run it and stop on any failure.
execFileSync('node', [join(ROOT, 'scripts/check-consistency.mjs')], { stdio: 'inherit' });

const testUtterances = new Set(parseCsv(readFileSync(join(ROOT, 'test-set/test-set.csv'), 'utf8')).rows.map(r => r.customer_says.trim()));
const rows = parseCsv(readFileSync(join(ROOT, 'practice/practice-conversations.csv'), 'utf8')).rows
  .filter(r => r.id >= firstId && r.id <= lastId);

const sf = args => JSON.parse(execFileSync('sf', [...args, '--target-org', org, '--json'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }));
const outDir = join(ROOT, 'practice/runs', new Date().toISOString().slice(0, 10));
mkdirSync(outDir, { recursive: true });

for (const row of rows) {
  const turns = [row.customer_turn_1, row.customer_turn_2].filter(Boolean);
  if (turns.some(t => testUtterances.has(t.trim()))) throw new Error(`${row.id} matches a test question; refusing to send it`);
  const sessionId = sf(['agent', 'preview', 'start', '--api-name', AGENT]).result.sessionId;
  const transcript = [];
  try {
    for (const turn of turns) {
      const reply = sf(['agent', 'preview', 'send', '--api-name', AGENT, '--session-id', sessionId, '--utterance', turn]);
      transcript.push({ customer: turn, agent: (reply.result.messages ?? []).map(m => m.message).join('\n') });
    }
  } finally {
    try { sf(['agent', 'preview', 'end', '--api-name', AGENT, '--session-id', sessionId]); } catch { /* already ended */ }
  }
  writeFileSync(join(outDir, `${row.id}.json`), JSON.stringify({ id: row.id, category: row.category, sessionId, at: new Date().toISOString(), transcript }, null, 2) + '\n');
  console.log(`${row.id}  ${turns.length} turn(s)  session ${sessionId}`);
}
console.log(`\n${rows.length} practice conversations saved to ${outDir.replace(ROOT, '')}`);
