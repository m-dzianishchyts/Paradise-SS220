"""
DO NOT MANUALLY RUN THIS SCRIPT.
---------------------------------

Expected environmental variables:
-----------------------------------
GITHUB_REPOSITORY: Github action variable representing the active repo (Action provided)
BOT_TOKEN: A repository account token, this will allow the action to push the changes (Action provided)
GITHUB_EVENT_PATH: path to JSON file containing the event info (Action provided)
"""
import os
import re
import copy
import json
import github
import github.PullRequest
import github.Label
import github.IssueEvent

from pathlib import Path
from ruamel.yaml import YAML

DISCORD_EMBED_DESCRIPTION_LIMIT = 4096

CL_BODY_PATTERN = re.compile(r"(:cl:|🆑)[ \t]*(?P<author>.+?)?\s*\n(?P<content>(.|\n)*?)\n/(:cl:|🆑)", re.MULTILINE)
CL_SPLIT_PATTERN = re.compile(r"\s*((?P<tag>\w+)\s*:)?\s*(?P<message>.*)")

TAGS_CONFIG_PATH = Path.cwd().joinpath("tags.yml")

LABEL_CL_INVALID = ":scroll: CL невалиден"
LABEL_CL_VALID = ":scroll: CL валиден"
LABEL_CL_NOT_NEEDED = ":scroll: CL не требуется"


class ChangelogException(Exception):
    pass


def load_yaml_config(path: str | Path) -> dict[str, dict[str, str]]:
    """Load YAML configuration from a file."""
    with open(path, 'r') as file:
        yaml = YAML(typ='safe', pure=True)
        return yaml.load(file)


def is_label_set_manually(label_name: str, pr_events: list[github.IssueEvent], bot_id: int):
    """Find latest event for the label and make sure it wasn't set by the bot."""
    events_labeled = list(event for event in pr_events if event.event == "labeled" and event.label.name == label_name)
    events_sorted = sorted(events_labeled, key=lambda event: event.created_at, reverse=True)
    if len(events_sorted):
        raise Exception(f"No event found related to label '{label_name}'")

    return events_sorted[0].actor.id != bot_id


def add_label_safe(label_name: str, pr: github.PullRequest):
    if not any(label.name == label_name for label in pr.labels):
        pr.add_to_labels(label_name)


def remove_label_safe(label_name: str, pr: github.PullRequest):
    if any(label.name == label_name for label in pr.labels):
        pr.remove_from_labels(label_name)


def update_labels(pr: github.PullRequest, cl_required: bool = True, cl_valid: bool = None):
    """Update PR labels based on validation result."""
    if not cl_required:
        remove_label_safe(LABEL_CL_VALID, pr)
        remove_label_safe(LABEL_CL_INVALID, pr)
        add_label_safe(LABEL_CL_NOT_NEEDED, pr)
        return

    if cl_valid is None:
        raise ChangelogException("Changelog is required but no validation result is provided.")

    if cl_valid:
        remove_label_safe(LABEL_CL_INVALID, pr)
        add_label_safe(LABEL_CL_VALID, pr)
    else:
        remove_label_safe(LABEL_CL_VALID, pr)
        add_label_safe(LABEL_CL_INVALID, pr)


def validate_changelog(changelog: dict):
    """Validate the parsed changelog."""
    if not changelog:
        raise ChangelogException("No changelog.")
    if not changelog["author"]:
        raise ChangelogException("The changelog has no author.")
    if len(changelog["changes"]) == 0:
        raise ChangelogException("No changes found in the changelog. "
                                 "Use special label or NPFC if changelog is not expected.")

    message = "\n".join(map(lambda change: f"{change['tag']} {change['message']}", changelog["changes"]))
    if len(message) > DISCORD_EMBED_DESCRIPTION_LIMIT:
        raise ChangelogException(f"The changelog exceeds the length limit ({DISCORD_EMBED_DESCRIPTION_LIMIT}).")


def emojify_changelog(changelog: dict, tags_config: dict):
    """Replace changelog tags with corresponding emojis."""
    discord_tags = tags_config["discord"]
    changelog_copy = copy.deepcopy(changelog)
    for change in changelog_copy["changes"]:
        if change["tag"] in discord_tags:
            change["tag"] = discord_tags[change["tag"]]
        else:
            raise ChangelogException(f"Invalid tag for emoji: {change}")
    return changelog_copy


def parse_changelog(message: str, tags_config: dict[str, dict[str, str]]) -> dict:
    """Parse changelog from PR message."""
    tag_groups, tag_default_messages = tags_config["tags"], tags_config["defaults"]

    cl_parse_result = CL_BODY_PATTERN.search(message)
    if cl_parse_result is None:
        raise ChangelogException("Failed to parse the changelog. Check changelog format.")
    cl_changes = []
    for cl_line in cl_parse_result.group("content").splitlines():
        if not cl_line:
            continue
        change_parse_result = CL_SPLIT_PATTERN.search(cl_line)
        if not change_parse_result:
            raise ChangelogException(f"Invalid change: '{cl_line}'")

        tag, message = change_parse_result["tag"], change_parse_result["message"]

        if tag and tag not in tag_groups.keys():
            raise ChangelogException(f"Invalid tag: '{cl_line}'. Valid tags: {', '.join(tag_groups.keys())}")
        if not message:
            raise ChangelogException(f"No message for change: '{cl_line}'")
        if message in list(tag_default_messages.values()):
            raise ChangelogException(f"Don't use default message for change: '{cl_line}'")

        if tag:
            cl_changes.append({
                "tag": tags_config['tags'][tag],
                "message": message
            })
        elif len(cl_changes):
            # Append line without a tag to the previous change
            cl_changes[-1]["message"] += f" {change_parse_result['message']}"
        else:
            raise ChangelogException(f"Change with no tag: {cl_line}")

    if len(cl_changes) == 0:
        raise ChangelogException("No changes found in the changelog. Use special label if changelog is not expected.")

    return {
        "author": str.strip(cl_parse_result.group("author") or "") or None,  # We need this to be None, not empty
        "changes": cl_changes
    }


def build_changelog(pr: github.PullRequest, tags_config: dict[str, dict[str, str]]) -> dict:
    """Build and return a structured changelog."""
    changelog = parse_changelog(pr.body, tags_config)
    changelog["author"] = changelog.get("author") or pr.user.login
    return changelog


def process_pull_request(pr: github.PullRequest, tags_config: dict[str, dict[str, str]]):
    """Process and validate the pull request's changelog."""
    try:
        changelog = build_changelog(pr, tags_config)
        changelog_emojified = emojify_changelog(changelog, tags_config)
        validate_changelog(changelog_emojified)
    except ChangelogException as e:
        print(f"Changelog parsing error: {e}")
        return False
    return True


def main():
    repo_name = os.environ["GITHUB_REPOSITORY"]
    event_path = os.environ["GITHUB_EVENT_PATH"]
    token = os.environ["BOT_TOKEN"]
    bot_id = int(os.environ["BOT_ID"])

    with open(event_path, 'r') as f:
        event_data = json.load(f)

    git = github.Github(token)
    repo = git.get_repo(repo_name)
    pr = repo.get_pull(event_data['number'])
    pr_is_mirror = pr.title.startswith("[MIRROR]")
    pr_has_npfc = "NPFC".casefold() in pr.body.casefold()
    pr_has_manual_label = any(label.name == LABEL_CL_NOT_NEEDED for label in pr.labels) \
                          and is_label_set_manually(LABEL_CL_NOT_NEEDED, list(pr.get_issue_events()), bot_id)

    cl_required = True
    pr.get_issue_events()
    if pr_is_mirror:
        print("PR is a mirror PR - changelog not needed.")
        cl_required = False

    if pr_has_npfc:
        print("PR is marked as not requiring a changelog (NPFC).")
        cl_required = False

    if pr_has_manual_label:
        print("PR is marked as not requiring a changelog (label).")
        cl_required = False

    if not cl_required:
        update_labels(pr, cl_required=False)
        print("Changelog is not needed - no validation is performed.")
        return

    tags_config = load_yaml_config(TAGS_CONFIG_PATH)
    cl_valid = process_pull_request(pr, tags_config)
    update_labels(pr, cl_valid=cl_valid)

    print(f"Changelog is {'valid' if cl_valid else 'invalid'}.")
    if not cl_valid:
        exit(2)


if __name__ == "__main__":
    main()
