// Scores the raw Testing Center results for one phase of the test.
//
//   node scripts/score-results.mjs baseline      (or: npm run score -- baseline)
//   node scripts/score-results.mjs after
//
// Reads results/<phase>/run-1..3/test-result-*.json, exactly as Testing Center
// wrote them, and writes two files next to them:
//   scoring-sheet.csv  the repo's scoring sheet, filled in with Pass or Fail
//   scores.md          the per-category table and every failed check
//
// The raw files are never changed. The scores are automated and come before the
// human review of the AI-judged answers (see test-set/README.md).
import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT, isMain, parseCsv } from './lib.mjs';
import { SUBAGENT_API_NAMES, ACTION_API_NAMES, expectedActions } from './build-test-spec.mjs';

// Testing Center does not list these among a run's invoked actions: the
// knowledge lookup and the template's escalation step. Amended after Run 1 of
// the baseline, before any scoring, and applied the same way to every run.
export const NOT_RECORDED = new Set([ACTION_API_NAMES['Answer Questions with Knowledge'], ACTION_API_NAMES.Escalate]);
// The platform's own injection guard can catch OT-04 before any subagent runs.
export const EXTRA_TOPICS = { 'OT-04': ['Prompt_Injection'] };

export function recordedActions(generatedData) {
  const raw = JSON.parse(generatedData.invokedActions || '[]');
  return [...new Set(raw.flat(Infinity).map(a => a?.function?.name).filter(Boolean))].sort();
}

export function scoreCase(row, testCase, answerOverride) {
  const g = testCase.generatedData ?? {};
  const topic = g.topic ?? '';
  const topics = [SUBAGENT_API_NAMES[row.expected_subagent], ...(EXTRA_TOPICS[row.id] ?? [])];
  const subagentOk = topics.some(t => topic.includes(t));
  const want = expectedActions(row).filter(a => !NOT_RECORDED.has(a)).sort();
  const got = recordedActions(g);
  const actionOk = JSON.stringify(want) === JSON.stringify(got);
  const answer = testCase.testResults.find(r => r.name === 'output_validation' || r.name === 'bot_response_rating');
  const answerOk = answerOverride ?? answer?.result === 'PASS';
  const failed = [!subagentOk && `subagent (${topic || 'none'})`, !actionOk && `action (got ${got.join('+') || 'none'}, want ${want.join('+') || 'none'})`, !answerOk && 'answer'].filter(Boolean);
  return { pass: failed.length === 0, failed, topic, got };
}

function loadRun(phase, n) {
  const dir = join(ROOT, 'results', phase, `run-${n}`);
  if (!existsSync(dir)) return null;
  const files = readdirSync(dir).filter(f => /^test-result-.*\.json$/.test(f));
  if (files.length !== 1) throw new Error(`${dir}: expected one test-result-*.json, found ${files.length}`);
  return JSON.parse(readFileSync(join(dir, files[0]), 'utf8'));
}

// Human overrides of the AI-judged answer check, from results/<phase>/overrides.csv.
// Only rows marked "accepted" are applied; "proposed" rows are listed, not applied.
export function loadOverrides(phase) {
  const f = join(ROOT, 'results', phase, 'overrides.csv');
  if (!existsSync(f)) return [];
  return parseCsv(readFileSync(f, 'utf8')).rows.map(o => ({ ...o, run: Number(o.run) }));
}

export function score(phase) {
  const { rows } = parseCsv(readFileSync(join(ROOT, 'test-set/test-set.csv'), 'utf8'));
  const overrides = loadOverrides(phase);
  const runs = [1, 2, 3].map(n => loadRun(phase, n));
  const missing = runs.flatMap((run, k) => (run ? [] : [`run-${k + 1}`]));
  if (missing.length) throw new Error(`results/${phase}/ is missing ${missing.join(', ')}. Score a phase after all three runs.`);
  const results = rows.map((row, i) => {
    const perRun = runs.map(run => {
      if (!run) return null;
      const tc = run.testCases.find(t => t.testNumber === i + 1);
      if (!tc) throw new Error(`${row.id}: missing from a run`);
      if (tc.inputs?.utterance !== row.customer_says) throw new Error(`${row.id}: utterance in the run does not match the test set`);
      const k = runs.indexOf(run) + 1;
      const o = overrides.find(x => x.id === row.id && x.run === k && x.status === 'accepted');
      return scoreCase(row, tc, o ? o.override === 'Pass' : undefined);
    });
    const passes = perRun.filter(r => r?.pass).length;
    return { row, perRun, overall: passes >= 2 };
  });
  return { runs, results, overrides };
}

// What the totals hide: questions that flipped between runs, the score on the
// answer check alone, and which checks the failed runs failed.
export function hidden(runs, results) {
  if (runs.some(r => !r)) return [];
  const flips = results.filter(r => new Set(r.perRun.map(x => x.pass)).size > 1).map(r => r.row.id);
  const answerOk = x => !x.failed.includes('answer');
  const perRunAnswer = [0, 1, 2].map(k => results.filter(r => answerOk(r.perRun[k])).length);
  const answerOnly = results.filter(r => r.perRun.filter(answerOk).length >= 2).length;
  const failedRuns = results.flatMap(r => r.perRun.filter(x => !x.pass));
  const has = (x, w) => x.failed.some(f => f.startsWith(w));
  return [
    '## What the totals hide',
    '',
    `- **Flipped with no change to the agent:** ${flips.length} (${flips.join(', ') || 'none'}).`,
    `- **Graded on the answer check alone:** ${answerOnly} of ${results.length} pass in at least two of three runs (runs: ${perRunAnswer.join(', ')}).`,
    `- **Failed runs:** ${failedRuns.length}. With a routing failure: ${failedRuns.filter(x => has(x, 'subagent')).length}. With an action failure: ${failedRuns.filter(x => has(x, 'action')).length}. Failed on the answer alone: ${failedRuns.filter(x => x.failed.length === 1 && x.failed[0] === 'answer').length}.`,
    '',
  ];
}

function write(phase, { runs, results, overrides }) {
  const dir = join(ROOT, 'results', phase);
  const pf = r => (r ? (r.pass ? 'Pass' : 'Fail') : '');
  const esc = s => (/[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
  const lines = ['ID,Category,Run 1,Run 2,Run 3,Result (2 of 3),Notes and overrides'];
  results.forEach(({ row, perRun }, i) => {
    const r = i + 2;
    const notes = perRun.map((x, k) => (x && !x.pass ? `R${k + 1}: ${x.failed.join('; ')}` : '')).filter(Boolean).join(' | ');
    lines.push([row.id, row.category, ...perRun.map(pf), `=IF(COUNTIF(C${r}:E${r},"Pass")>=2,"Pass","Fail")`, notes].map(esc).join(','));
  });
  const last = results.length + 1;
  lines.push(['TOTAL PASSED', '', ...['C', 'D', 'E', 'F'].map(c => `=COUNTIF(${c}2:${c}${last},"Pass")`), ''].map(esc).join(','));
  writeFileSync(join(dir, 'scoring-sheet.csv'), lines.join('\n') + '\n');

  const cats = [...new Set(results.map(r => r.row.category))];
  const count = (rs, k) => rs.filter(r => r.perRun[k]?.pass).length;
  const md = [
    `# ${phase === 'baseline' ? 'Baseline' : 'After'} results: automated scores`,
    '',
    `Scored by \`scripts/score-results.mjs\` from the raw Testing Center files in this folder.`,
    'The answer check is AI-judged. Accepted human overrides are applied; proposed ones are not.',
    '',
    '| Category | Questions | Run 1 | Run 2 | Run 3 | Passed (2 of 3 runs) |',
    '| --- | --- | --- | --- | --- | --- |',
    ...cats.map(c => {
      const rs = results.filter(r => r.row.category === c);
      return `| ${c} | ${rs.length} | ${[0, 1, 2].map(k => (runs[k] ? count(rs, k) : '')).join(' | ')} | ${rs.filter(r => r.overall).length} |`;
    }),
    `| **Total** | **${results.length}** | ${[0, 1, 2].map(k => (runs[k] ? `**${count(results, k)}**` : '')).join(' | ')} | **${results.filter(r => r.overall).length}** |`,
    '',
    ...hidden(runs, results),
    '## Human overrides of the answer check',
    '',
    overrides.length ? `${overrides.filter(o => o.status === 'accepted').length} accepted and applied, ${overrides.filter(o => o.status !== 'accepted').length} proposed and not applied. See overrides.csv.` : 'None.',
    '',
    ...(overrides.length ? ['| ID | Run | Judge | Override | Status |', '| --- | --- | --- | --- | --- |', ...overrides.map(o => `| ${o.id} | ${o.run} | ${o.judge} | ${o.override} | ${o.status} |`), ''] : []),
    '## Every failed check',
    '',
    '| ID | Run | Failed checks |',
    '| --- | --- | --- |',
    ...results.flatMap(({ row, perRun }) => perRun.map((x, k) => (x && !x.pass ? `| ${row.id} | ${k + 1} | ${x.failed.join('; ')} |` : null)).filter(Boolean)),
    '',
  ];
  writeFileSync(join(dir, 'scores.md'), md.join('\n'));
}

if (isMain(import.meta.url)) {
  const phase = process.argv[2];
  if (!['baseline', 'after'].includes(phase)) {
    console.error('usage: node scripts/score-results.mjs baseline|after');
    process.exit(2);
  }
  const s = score(phase);
  write(phase, s);
  console.log(readFileSync(join(ROOT, 'results', phase, 'scores.md'), 'utf8').split('## Every failed check')[0]);
}
