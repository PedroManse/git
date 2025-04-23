#!/bin/sh

test_description='Test basic issue functionality'

. ./test-lib.sh

# Add the contrib/git-issue directory to PATH
PATH="$GIT_BUILD_DIR/contrib/git-issue:$PATH"
test_expect_success 'verify PATH setup' '
    test -x "$GIT_BUILD_DIR/contrib/git-issue/git-issue-create" &&
    test -x "$GIT_BUILD_DIR/contrib/git-issue/git-issue-ls" &&
    test -x "$GIT_BUILD_DIR/contrib/git-issue/git-issue-show" &&
    test -x "$GIT_BUILD_DIR/contrib/git-issue/git-issue-state" &&
    test -x "$GIT_BUILD_DIR/contrib/git-issue/git-issue-comment"
'

test_expect_success 'setup' '
	git init test-repo &&
	cd test-repo &&
	test_commit initial
'

test_expect_success 'git issue-create creates a new issue' '
	git issue-create --title "Test issue" -m "This is a test issue" &&
	git rev-parse --verify refs/issues/0001 &&
	git cat-file -p refs/issues/0001 | grep "Title: Test issue" &&
	git cat-file -p refs/issues/0001 | grep "State: open" &&
	git cat-file -p refs/issues/0001 | grep "This is a test issue"
'

test_expect_success 'git issue-create increments issue ID' '
git issue-create --title "Second issue" -m "This is another test issue" &&
	git rev-parse --verify refs/issues/0002 &&
	git cat-file -p refs/issues/0002 | grep "Title: Second issue" &&
	git cat-file -p refs/issues/0002 | grep "State: open" &&
	git cat-file -p refs/issues/0002 | grep "This is another test issue"
'

test_expect_success 'git issue-create with labels' '
	git issue-create --title "Issue with labels" -m "This issue has labels" --labels "bug,enhancement" &&
	git rev-parse --verify refs/issues/0003 &&
	git cat-file -p refs/issues/0003 | grep "Labels: bug,enhancement"
'

test_expect_success 'git issue-create with assignee' '
	git issue-create --title "Issue with assignee" -m "This issue has an assignee" --assignee "user@example.com" &&
	git rev-parse --verify refs/issues/0004 &&
	git cat-file -p refs/issues/0004 | grep "Assignee: user@example.com"
'

test_expect_success 'git issue-comment adds a comment' '
	git issue-comment 1 -m "This is a comment on issue 1" &&
	git log -1 --format=%B refs/issues/0001 | grep "This is a comment on issue 1"
'

test_expect_success 'git issue-state changes issue state' '
	git issue-state 1 --state closed &&
	git log -1 --format=%B refs/issues/0001 | grep "State: closed"
'

test_expect_success 'git issue-state with release and fixed-by' '
	git issue-state 2 --state closed --release v1.0 --fixed-by $(git rev-parse HEAD) &&
	git log -1 --format=%B refs/issues/0002 | grep "State: closed" &&
	git log -1 --format=%B refs/issues/0002 | grep "Release: v1.0" &&
	git log -1 --format=%B refs/issues/0002 | grep "Fixed-By: $(git rev-parse HEAD)"
'

test_expect_success 'git issue-ls lists issues' '
	git issue-ls > issues.out &&
	grep "#0001 \[closed\] Test issue" issues.out &&
	grep "#0002 \[closed\] Second issue" issues.out &&
	grep "#0003 \[open\] Issue with labels" issues.out &&
	grep "#0004 \[open\] Issue with assignee" issues.out
'

test_expect_success 'git issue-ls filters by state' '
	git issue-ls --state open > open-issues.out &&
	grep "#0003 \[open\]" open-issues.out &&
	grep "#0004 \[open\]" open-issues.out &&
	! grep "#0001 \[closed\]" open-issues.out &&
	! grep "#0002 \[closed\]" open-issues.out
'

test_expect_success 'git issue-ls filters by label' '
	git issue-ls --label bug > bug-issues.out &&
	grep "#0003 \[open\] Issue with labels" bug-issues.out &&
	! grep "#0001 \[closed\] Test issue" bug-issues.out &&
	! grep "#0002 \[closed\] Second issue" bug-issues.out &&
	! grep "#0004 \[open\] Issue with assignee" bug-issues.out
'

test_expect_success 'git issue-ls filters by assignee' '
	git issue-ls --assignee "user@example.com" > assigned-issues.out &&
	grep "#0004 \[open\] Issue with assignee" assigned-issues.out &&
	! grep "#0001 \[closed\] Test issue" assigned-issues.out &&
	! grep "#0002 \[closed\] Second issue" assigned-issues.out &&
	! grep "#0003 \[open\] Issue with labels" assigned-issues.out
'

test_expect_success 'git issue-show displays issue details' '
	git issue-show 1 > issue1.out &&
	grep "Issue #1 \[closed\]: Test issue" issue1.out &&
	grep "This is a test issue" issue1.out &&
	grep "This is a comment on issue 1" issue1.out
'

test_expect_success 'git issue-show displays issue with labels and assignee' '
	git issue-show 3 > issue3.out &&
	grep "Issue #3 \[open\]: Issue with labels" issue3.out &&
	grep "Labels: bug,enhancement" issue3.out &&
	grep "This issue has labels" issue3.out
'

test_expect_success 'git issue-show displays issue with release and fixed-by' '
	git issue-show 2 > issue2.out &&
	grep "Issue #2 \[closed\]: Second issue" issue2.out &&
	grep "Release: v1.0" issue2.out &&
	grep "Fixed-By: $(git rev-parse HEAD)" issue2.out
'

test_done
