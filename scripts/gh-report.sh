#!/usr/bin/env bash
set -euo pipefail

# Requirements:
# - GitHub CLI: https://cli.github.com/ (gh)
# - jq: https://stedolan.github.io/jq/
# - Auth: gh auth login (must have repo read perms)
#
# Output:
# - reports/<DATE_RANGE>-work-summary.md

DATE_RANGE="${DATE_RANGE:-2025-09-01..2025-09-30}"
OUT_DIR="${OUT_DIR:-reports}"
OUT_FILE="${OUT_FILE:-${OUT_DIR}/${DATE_RANGE}-work-summary.md}"

mkdir -p "${OUT_DIR}"

header() {
  echo "# Work summary"
  echo
  echo "- Time window: ${DATE_RANGE}"
  echo "- Sources:"
  echo "  - PRs merged in: cwbi-apps/screening-tool-api-support, cwbi-apps/screening-tool-ui"
  echo "  - Issues closed (Done) in: USACE/chart-docs"
  echo
}

fetch_prs_md() {
  local repo="$1"
  local query="repo:${repo} is:pr is:merged merged:${DATE_RANGE}"

  gh api graphql -f query='
    query($q:String!) {
      search(type: ISSUE, query: $q, first: 100) {
        nodes {
          ... on PullRequest {
            number
            title
            url
            mergedAt
            author { login }
            labels(first: 30) { nodes { name } }
          }
        }
      }
    }
  ' -F q="${query}" \
  | jq -r --arg repo "${repo}" '
      .data.search.nodes
      | sort_by(.mergedAt)
      | ( "## " + $repo + " — PRs merged"
          , ""
          , ( if length == 0 then "_None_" else
              (map("* [#\(.number)](\(.url)) - \(.title) — @\(.author.login) — \(.mergedAt[0:10])"
                 + (if (.labels.nodes|length)>0 then " — labels: " + ((.labels.nodes|map(.name))|join(", ")) else "" end)
              )[]) end)
          , ""
        )
    '
}

fetch_closed_issues_md() {
  local repo="$1"
  local query="repo:${repo} is:issue is:closed closed:${DATE_RANGE}"

  gh api graphql -f query='
    query($q:String!) {
      search(type: ISSUE, query: $q, first: 100) {
        nodes {
          ... on Issue {
            number
            title
            url
            closedAt
            author { login }
            labels(first: 30) { nodes { name } }
          }
        }
      }
    }
  ' -F q="${query}" \
  | jq -r --arg repo "${repo}" '
      .data.search.nodes
      | sort_by(.closedAt)
      | ( "## " + $repo + " — Issues closed (Done)"
          , ""
          , ( if length == 0 then "_None_" else
              (map("* [#\(.number)](\(.url)) - \(.title) — @\(.author.login) — closed \(.closedAt[0:10])"
                 + (if (.labels.nodes|length)>0 then " — labels: " + ((.labels.nodes|map(.name))|join(", ")) else "" end)
              )[]) end)
          , ""
        )
    '
}

# ---------- New: helpers to list item numbers in range ----------
list_prs_in_range() {
  local repo="$1"
  local query="repo:${repo} is:pr is:merged merged:${DATE_RANGE}"
  gh api graphql -f query='
    query($q:String!){
      search(type: ISSUE, query: $q, first: 100){
        nodes{ ... on PullRequest { number mergedAt title url } }
      }
    }' -F q="${query}" \
  | jq -r '.data.search.nodes | sort_by(.mergedAt) | map({number, title, url})'
}

list_issues_in_range() {
  local repo="$1"
  local query="repo:${repo} is:issue is:closed closed:${DATE_RANGE}"
  gh api graphql -f query='
    query($q:String!){
      search(type: ISSUE, query: $q, first: 100){
        nodes{ ... on Issue { number closedAt title url } }
      }
    }' -F q="${query}" \
  | jq -r '.data.search.nodes | sort_by(.closedAt) | map({number, title, url})'
}

# ---------- New: formatters for comments ----------
# Prints markdown bullet list from an array of comment objects with fields:
#   created_at, user.login, body, html_url
_format_comment_list() {
  jq -r '
    def trunc: (.|tostring)[0:200];
    if length == 0 then
      "_None_"
    else
      map(
        "* \(.created_at[0:10]) — @\(.user.login): \(((.body // "") | gsub("\r";"") | split("\n")[0] | trunc))"
        + (if (.html_url? and .html_url != null) then " [link](\(.html_url))" else "" end)
      )[]
    end
  '
}

# Issue comments on PRs and Issues share the same endpoint
issue_comments_md() {
  local repo="$1" number="$2"
  # --paginate may output multiple arrays; merge them with -s add
  gh api --paginate "repos/${repo}/issues/${number}/comments" \
    | jq -s 'add // []' \
    | _format_comment_list
}

# Pull request review comments (on code)
pr_review_comments_md() {
  local repo="$1" number="$2"
  gh api --paginate "repos/${repo}/pulls/${number}/comments" \
    | jq -s 'add // []' \
    | jq -r '
        if (length==0) then "_None_" else
          (map("* \(.created_at[0:10]) — @\(.user.login) on `\(.path // "unknown"):\(.line // 0)`: \((.body // "" | gsub("\r";"") | split("\n")[0]) | .[0:200]) [link](\(.html_url))")[])
        end
      '
}

# Pull request reviews (Approve/Comment/Request changes) + body
pr_reviews_md() {
  local repo="$1" number="$2"
  gh api --paginate "repos/${repo}/pulls/${number}/reviews" \
    | jq -s 'add // []' \
    | jq -r '
        if (length==0) then "_None_" else
          (map("* \(.submitted_at[0:10]) — @\(.user.login) — **\(.state)**: \((.body // "" | gsub("\r";"") | split("\n")[0]) | .[0:200])")[])
        end
      '
}

# ---------- New: “Discussion details” builders ----------
discussion_for_prs() {
  local repo="$1"
  local items
  items="$(list_prs_in_range "${repo}")"

  echo "## ${repo} — Discussion details for PRs"
  echo

  if [[ "$(jq 'length' <<<"$items")" -eq 0 ]]; then
    echo "_None_"
    echo
    return 0
  fi

  jq -c '.[]' <<<"$items" | while read -r row; do
    local number title url
    number="$(jq -r '.number' <<<"$row")"
    title="$(jq -r '.title' <<<"$row")"
    url="$(jq -r '.url' <<<"$row")"

    echo "### PR #${number} — ${title}"
    echo "${url}"
    echo
    echo "**Issue comments**"
    issue_comments_md "${repo}" "${number}"
    echo
    echo "**Review comments**"
    pr_review_comments_md "${repo}" "${number}"
    echo
    echo "**Reviews**"
    pr_reviews_md "${repo}" "${number}"
    echo
  done
}

discussion_for_issues() {
  local repo="$1"
  local items
  items="$(list_issues_in_range "${repo}")"

  echo "## ${repo} — Discussion details for Issues"
  echo

  if [[ "$(jq 'length' <<<"$items")" -eq 0 ]]; then
    echo "_None_"
    echo
    return 0
  fi

  jq -c '.[]' <<<"$items" | while read -r row; do
    local number title url
    number="$(jq -r '.number' <<<"$row")"
    title="$(jq -r '.title' <<<"$row")"
    url="$(jq -r '.url' <<<"$row")"

    echo "### Issue #${number} — ${title}"
    echo "${url}"
    echo
    echo "**Comments**"
    issue_comments_md "${repo}" "${number}"
    echo
  done
}

# ---------- Build the report ----------
{
  header
  fetch_prs_md "cwbi-apps/screening-tool-api-support"
  fetch_prs_md "cwbi-apps/screening-tool-ui"
  fetch_closed_issues_md "USACE/chart-docs"

  echo
  echo "# Discussion details"
  echo

  discussion_for_prs "cwbi-apps/screening-tool-api-support"
  discussion_for_prs "cwbi-apps/screening-tool-ui"
  discussion_for_issues "USACE/chart-docs"
} > "${OUT_FILE}"

echo "Wrote ${OUT_FILE}"
