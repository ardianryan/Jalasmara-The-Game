import assert from 'node:assert/strict';
import test from 'node:test';
import { pushBranch } from './push-remotes.mjs';

function fixture(failingRemote) {
  const pushes = [];
  return {
    pushes,
    run(args) {
      if (args[0] !== 'push') return '';
      pushes.push(args);
      if (args.includes(failingRemote)) throw new Error('Simulated rejected push');
      return '';
    },
  };
}

test('the same explicit branch reaches primary first, with CI skip only on GitLab', () => {
  const f = fixture();
  const results = pushBranch('work/example', { run: f.run });
  assert.deepEqual(results.map(r => r.remote), ['gitea', 'github', 'gitlab']);
  assert.deepEqual(f.pushes, [
    ['push', 'gitea', 'refs/heads/work/example:refs/heads/work/example'],
    ['push', 'github', 'refs/heads/work/example:refs/heads/work/example'],
    ['push', '-o', 'ci.skip', 'gitlab', 'refs/heads/work/example:refs/heads/work/example'],
  ]);
});

test('a primary failure prevents backup publication', () => {
  const f = fixture('gitea');
  assert.equal(pushBranch('work/example', { run: f.run }).length, 1);
  assert.equal(f.pushes.length, 1);
});

test('a backup failure still attempts the other backup and reports the failure', () => {
  const f = fixture('github');
  const result = pushBranch('work/example', { run: f.run });
  assert.equal(result[1].status, 'failed');
  assert.equal(result[2].status, 'pushed');
  assert.equal(f.pushes.length, 3);
});

test('dry run applies to every remote without force, mirror or deletion options', () => {
  const f = fixture();
  pushBranch('work/example', { run: f.run, dryRun: true });
  assert.ok(f.pushes.every(args => args.includes('--dry-run')));
  assert.ok(f.pushes.every(args => !args.some(arg => ['--force', '--mirror', '--all', '--delete'].includes(arg))));
  assert.throws(() => pushBranch('--mirror', { run: f.run }), /explicit local branch/);
});
