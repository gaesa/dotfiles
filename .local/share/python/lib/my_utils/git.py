from subprocess import run
from os.path import isdir, join, dirname
from os import environ, getcwd


def get_tracked_files(path: str = ".", tree_ish: str = "HEAD") -> list[str]:
    process = run(
        ["/usr/bin/git", "ls-tree", "--full-tree", "-r", "--name-only", tree_ish, path],
        capture_output=True,
        text=True,
    )
    if process.returncode == 0:
        return process.stdout.splitlines()
    else:
        raise SystemExit(process.stderr.rstrip())


def get_tracked_dirs(path: str = ".", tree_ish: str = "HEAD") -> list[str]:
    def add_dot(dir: str) -> str:
        return "." if dir == "" else dir

    return list(
        dict.fromkeys(
            map(lambda f: add_dot(dirname(f)), get_tracked_files(path, tree_ish))
        )
    )


def get_git_dir():
    if "GIT_DIR" in environ:
        return environ["GIT_DIR"]
    else:
        work_tree = get_work_tree_without_config()
        if work_tree is None:
            raise SystemExit("Can't find a git repository")
        else:
            return join(work_tree, ".git")


def get_work_tree_without_config(dir: str | None = None) -> str | None:
    if "GIT_WORK_TREE" in environ:
        return environ["GIT_WORK_TREE"]
    else:
        dir = getcwd() if dir is None else dir
        while dir != "/":
            if isdir(join(dir, ".git")):
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
