import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

function git(args) {
  const result = spawnSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr.trim() || `git exited ${result.status}`);
  return result.stdout.trim();
}

export function pushBranch(branch, { run = git, dryRun = false } = {}) {
  if (!branch || branch.startsWith('-')) throw new Error('An explicit local branch is required.');
  run(['check-ref-format', '--branch', branch]);
  const ref = `refs/heads/${branch}`;
  run(['show-ref', '--verify', ref]);
  const commit = run(['rev-parse', '--verify', `${ref}^{commit}`]);
  if (!/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(commit)) throw new Error('Cannot freeze the branch commit.');
  for (const remote of ['gitea', 'github', 'gitlab']) run(['remote', 'get-url', remote]);
  const results = [];
  for (const remote of ['gitea', 'github', 'gitlab']) {
    const args = ['push'];
    if (dryRun) args.push('--dry-run');
    if (remote === 'gitlab') args.push('-o', 'ci.skip');
    args.push(remote, `${commit}:${ref}`);
    try {
      run(args);
      results.push({ remote, commit, status: dryRun ? 'dry-run-ok' : 'pushed' });
    } catch (error) {
      results.push({ remote, commit, status: 'failed', error: error.message });
      // A failed primary push must not publish a new backup-only candidate.
      if (remote === 'gitea') break;
    }
  }
  return results;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    const dryRun = args.includes('--dry-run');
    const branches = args.filter(value => value !== '--dry-run');
    if (branches.length > 1 || branches.some(value => value.startsWith('-'))) {
      throw new Error('Usage: node scripts/push-remotes.mjs [branch] [--dry-run]');
    }
    const branch = branches[0] ?? git(['symbolic-ref', '--short', 'HEAD']);
    const results = pushBranch(branch, { dryRun });
    console.log(JSON.stringify({ branch, dryRun, results }, null, 2));
    if (results.length !== 3 || results.some(result => result.status === 'failed')) process.exitCode = 1;
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
