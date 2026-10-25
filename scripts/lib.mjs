// Shared helpers for the offline scripts. Node built-ins only, no dependencies.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

export const ROOT = new URL('..', import.meta.url).pathname;

/** Salesforce Knowledge__kav.Summary is a 1,000-character field. */
export const SUMMARY_LIMIT = 1000;

/** Parses an RFC 4180 CSV string into an array of row objects keyed by header. */
export function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') {
        field += '"';
        i++;
      } else if (c === '"') {
        quoted = false;
      } else {
        field += c;
      }
    } else if (c === '"') {
      quoted = true;
    } else if (c === ',') {
      row.push(field);
      field = '';
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else {
      field += c;
    }
  }
  if (field !== '' || row.length) {
    row.push(field);
    rows.push(row);
  }
  const [header, ...body] = rows.filter(r => r.some(cell => cell !== ''));
  return {
    header,
    rows: body.map(cells => Object.fromEntries(header.map((h, i) => [h, cells[i] ?? '']))),
    raw: body,
  };
}

/** Reads knowledge/*.md: front matter (title, urlName) plus the body text. */
export function readArticles() {
  const dir = join(ROOT, 'knowledge');
  return readdirSync(dir)
    .filter(f => f.endsWith('.md'))
    .sort()
    .map(file => {
      const text = readFileSync(join(dir, file), 'utf8');
      const m = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
      if (!m) throw new Error(`${file}: missing front matter`);
      const meta = Object.fromEntries(
        m[1].split('\n').map(line => {
          const i = line.indexOf(':');
          return [line.slice(0, i).trim(), line.slice(i + 1).trim().replace(/^"(.*)"$/, '$1')];
        }),
      );
      return { file, title: meta.title, urlName: meta.urlName, body: m[2].trim() };
    });
}
