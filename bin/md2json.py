#!/usr/bin/env python
#
# TODO:
# * some plugins are under sub-sections
# * Plugin something doesn't split properly on ###

import json
import re


def transform_mini_nvim_name(name: str) -> str:
    if "mini.nvim#mini." in name:
        _, plugin_name = name.split("#")
        return plugin_name
    return name


def transform_mini_nvim_path(path: str) -> str:
    if "echasnovski/mini.nvim#mini." in path:
        _, plugin_name = path.split("#")
        return f"echasnovski/{plugin_name}"
    return path


def transform_mini_nvim_url(url: str) -> str:
    if "echasnovski/mini.nvim#mini." in url:
        base_url, plugin_component = url.split("#")
        plugin_name = f"mini.{plugin_component}"
        return base_url.replace("mini.nvim", plugin_name) + ".git"
    elif "echasnovski/mini.nvim/blob/main/readmes/mini-" in url:
        url = url.replace(
            "echasnovski/mini.nvim/blob/main/readmes/mini-", "echasnovski/mini."
        )
        url = url.replace(".md", "")
    return url


# normalise filenames..
def transform_to_config_name(name: str) -> str:
    name = name.replace(".", "_")
    name = name.replace("-", "_")
    name = f"{name}.lua"
    return name


def parse_markdown(md):
    # Extract the portion after ## Plugin (case-insensitive and allowing spaces)
    plugin_section_match = re.search(
        r"##\s*Plugin\s*(\n+)?(.+)", md, re.DOTALL | re.IGNORECASE
    )

    if not plugin_section_match:
        raise ValueError(
            "Failed to find the '## Plugin' section in the provided markdown."
        )

    plugin_section = plugin_section_match.group(2)

    # Split the markdown based on subsection headings
    subsections = re.split(r"\n(?=###\s)", plugin_section)

    # Remove empty strings
    subsections = [section for section in subsections if section]

    data = {}

    for subsection in subsections:
        # Split the subsection into lines
        lines = subsection.split("\n")

        # First line is the subsection name
        subsection_name = lines[0].replace("###", "").strip()

        # Remaining lines are the list items
        items = lines[1:]

        repos = []

        for item in items:
            if item.startswith("- "):  # Ensure it's a list item
                # Extract repo name, repo link, and description
                match = re.match(r"- \[(.+)\]\((.+)\) - (.+)", item)
                if match:
                    repo_path, repo_link, description = match.groups()
                    repo_owner = ""
                    repo_name = ""
                    try:
                        repo_owner = repo_path.split("/")[0]
                        repo_name = repo_path.split("/")[1]
                    except IndexError:
                        repo_owner = ""
                        repo_name = repo_path

                    repos.append(
                        {
                            "path": transform_mini_nvim_path(repo_path),
                            "owner": repo_owner,
                            "name": transform_mini_nvim_name(repo_name),
                            "config": transform_to_config_name(
                                transform_mini_nvim_name(repo_name)
                            ),
                            "url": transform_mini_nvim_url(repo_link),
                            "description": description,
                        }
                    )

        # Add the extracted repos to the current subsection
        data[subsection_name] = repos

    return data


if __name__ == "__main__":
    file_name = "awesome-neovim/README.md"
    with open(file_name, "r", encoding="utf-8") as f:
        content = f.read()
    data = parse_markdown(content)
    print(json.dumps(data, indent=4))
