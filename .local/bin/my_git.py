from subprocess import run
from os.path import islink, isdir, join, dirname
from os import environ, getcwd


def get_tracked_files(path: str = getcwd()) -> list[str]:
    process = run(["/usr/bin/git", "ls-files", path], capture_output=True, text=True)
    if process.returncode == 0:
        files = process.stdout.splitlines()
        return list(filter(lambda file: not islink(file), files))
    else:
        raise SystemExit(process.stderr.rstrip())


def get_git_dir():
    if "GIT_DIR" in environ:
        return environ["GIT_DIR"]
    else:
        work_tree = get_work_tree_without_config()
        if work_tree is None:
            raise SystemExit("Can't find a git repository")
        else:
            return join(work_tree, ".git")


def get_work_tree_without_config(dir=getcwd()) -> str | None:
    if "GIT_WORK_TREE" in environ:
        return environ["GIT_WORK_TREE"]
    else:
        while dir != "/":
            if isdir(join(dir, "git")):
                return dir
            else:
                dir = dirname(dir)
        else:
            return None


def get_work_tree():
    work_tree = get_work_tree_without_config()
    if work_tree is None:
        from configparser import ConfigParser

        config = ConfigParser()
        git_dir = get_git_dir()
        config.read(join(git_dir, "config"))
        config_core = config["core"]
        if "worktree" in config_core:
            return config_core["worktree"]
        else:
            raise SystemExit("Can't find a git repository")
    else:
        return work_tree
