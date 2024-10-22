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

from pathlib import Path
from ruamel.yaml import YAML

DISCORD_EMBED_DESCRIPTION_LIMIT = 4096

CL_BODY_PATTERN = re.compile(r"(:cl:|🆑)[ \t]*(?P<author>.+?)?\s*\n(?P<content>(.|\n)*?)\n/(:cl:|🆑)", re.MULTILINE)
CL_SPLIT_PATTERN = re.compile(r"\s*((?P<tag>\w+)\s*:)?\s*(?P<message>.*)")

TAGS_CONFIG_PATH = Path.cwd().joinpath("tags.yml")

LABEL_CL_INVALID = ":scroll: CL невалиден"
LABEL_CL_VALID = ":scroll: CL валиден"
LABEL_CL_NOT_NEEDED = ":scroll: CL не требуется"


def load_yaml_config(path: str | Path) -> dict:
    """Load YAML configuration from a file."""
    with open(path, 'r') as file:
        yaml = YAML(typ='safe', pure=True)
        return yaml.load(file)


def find_label(label_name: str, pr_labels: list[github.Label]):
    return any(label.name == label_name for label in pr_labels)


def update_labels(pr: github.PullRequest, cl_required: bool = True, cl_valid: bool = None):
    """Update PR labels based on validation result."""
    if not cl_required:
        if find_label(LABEL_CL_VALID, pr.labels):
            pr.remove_from_labels(LABEL_CL_VALID)
        if find_label(LABEL_CL_INVALID, pr.labels):
            pr.remove_from_labels(LABEL_CL_INVALID)
        if not find_label(LABEL_CL_NOT_NEEDED, pr.labels):
            pr.add_to_labels(LABEL_CL_NOT_NEEDED)
        return

    if cl_valid is None:
        raise Exception("Changelog is required but no validation result is provided.")

    if cl_valid:
        if find_label(LABEL_CL_INVALID, pr.labels):
            pr.remove_from_labels(LABEL_CL_INVALID)
        if not find_label(LABEL_CL_VALID, pr.labels):
            pr.add_to_labels(LABEL_CL_VALID)
    else:
        if find_label(LABEL_CL_VALID, pr.labels):
            pr.remove_from_labels(LABEL_CL_VALID)
        if not find_label(LABEL_CL_INVALID, pr.labels):
            pr.add_to_labels(LABEL_CL_INVALID)


def validate_changelog(changelog: dict):
    """Validate the parsed changelog."""
    if not changelog:
        raise Exception("No changelog.")
    if not changelog["author"]:
        raise Exception("The changelog has no author.")
    if len(changelog["changes"]) == 0:
        raise Exception("No changes found in the changelog. Use special label or NPFC if changelog is not expected.")

    message = "\n".join(map(lambda change: f"{change['tag']} {change['message']}", changelog["changes"]))
    if len(message) > DISCORD_EMBED_DESCRIPTION_LIMIT:
        raise Exception(f"The changelog exceeds the length limit ({DISCORD_EMBED_DESCRIPTION_LIMIT}). Shorten it.")


def emojify_changelog(changelog: dict, tags_config: dict):
    """Replace changelog tags with corresponding emojis."""
    discord_tags = tags_config["discord"]
    changelog_copy = copy.deepcopy(changelog)
    for change in changelog_copy["changes"]:
        if change["tag"] in discord_tags:
            change["tag"] = discord_tags[change["tag"]]
        else:
            raise Exception(f"Invalid tag for emoji: {change}")
    return changelog_copy


def parse_changelog(message: str, tags_config: dict) -> dict:
    """Parse changelog from PR message."""
    tag_groups, tag_default_messages = tags_config["tags"], tags_config["defaults"]

    cl_parse_result = CL_BODY_PATTERN.search(message)
    if cl_parse_result is None:
        raise Exception("Failed to parse the changelog. Check changelog format.")
    cl_changes = []
    for cl_line in cl_parse_result.group("content").splitlines():
        if not cl_line:
            continue
        change_parse_result = CL_SPLIT_PATTERN.search(cl_line)
        if not change_parse_result:
            raise Exception(f"Invalid change: '{cl_line}'")

        tag, message = change_parse_result["tag"], change_parse_result["message"]

        if tag and tag not in tag_groups.keys():
            raise Exception(f"Invalid tag: '{cl_line}'. Valid tags: {', '.join(tag_groups.keys())}")
        if not message:
            raise Exception(f"No message for change: '{cl_line}'")
        if message in list(tag_default_messages[tag_groups[tag]].values()):
            raise Exception(f"Don't use default message for change: '{cl_line}'")

        if tag:
            cl_changes.append({
                "tag": tags_config['tags'][tag],
                "message": message
            })
        elif len(cl_changes):
            # Append line without a tag to the previous change
            cl_changes[-1]["message"] += f" {change_parse_result['message']}"
        else:
            raise Exception(f"Change with no tag: {cl_line}")

    if len(cl_changes) == 0:
        raise Exception("No changes found in the changelog. Use special label if changelog is not expected.")

    return {
        "author": str.strip(cl_parse_result.group("author") or "") or None,  # We need this to be None, not empty
        "changes": cl_changes
    }


def build_changelog(pr: github.PullRequest, tags_config: dict) -> dict:
    """Build and return a structured changelog."""
    changelog = parse_changelog(pr.body, tags_config)
    changelog["author"] = changelog.get("author") or pr.user.login
    return changelog


def process_pull_request(pr: github.PullRequest, tags_config: dict):
    """Process and validate the pull request's changelog."""
    try:
        changelog = build_changelog(pr, tags_config)
        changelog_emojified = emojify_changelog(changelog, tags_config)
        validate_changelog(changelog_emojified)
    except Exception as e:
        print(f"Changelog parsing error: {e}")
        return False
    return True


def main():
    repo_name = os.getenv("GITHUB_REPOSITORY")
    token = os.getenv("BOT_TOKEN")
    event_path = os.getenv("GITHUB_EVENT_PATH")

    if not token:
        print("BOT_TOKEN was not provided.")
        return

    with open(event_path, 'r') as f:
        event_data = json.load(f)

    git = github.Github(token)
    repo = git.get_repo(repo_name)
    pr = repo.get_pull(event_data['number'])
    pr_is_mirror = pr.title.startswith("[MIRROR]")

    cl_required = True
    if pr_is_mirror:
        print("PR is a mirror PR - changelog not needed.")
        cl_required = False

    if any(label.name == LABEL_CL_NOT_NEEDED for label in pr.labels):
        print("PR is marked as not requiring a changelog (label).")
        cl_required = False

    if "NPFC".casefold() in pr.body.casefold():
        print("PR is marked as not requiring a changelog (NPFC).")
        cl_required = False

    if not cl_required:
        update_labels(pr, cl_required=False)
        print("Changelog is not needed - no validation is performed.")
        return

    tags_config = load_yaml_config(TAGS_CONFIG_PATH)
    validation_result = process_pull_request(pr, tags_config)
    update_labels(pr, cl_valid=validation_result)

    print(f"Changelog is {'valid' if validation_result else 'invalid'}.")


if __name__ == "__main__":
    main()
