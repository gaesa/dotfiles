import logging
from itertools import filterfalse
from os import environ, getcwd
from os.path import dirname, exists, isdir, islink, join
from subprocess import CalledProcessError, run


def get_tracked_files(
    path: str = ".",
    tree_ish: str = "HEAD",
    include_link: bool = True,
    check_existence: bool = True,
) -> list[str]:
    cmd = ["git", "ls-tree", "--full-tree", "-r", "--name-only", tree_ish, path]
    p = run(
        cmd,
        capture_output=True,
        text=True,
    )
    if p.returncode == 0:
        return (  # pyright: ignore [reportReturnType]
            (lambda f: list(f) if not isinstance(f, list) else f)
            if include_link
            else (lambda f: list(filterfalse(islink, f)))
        )(
            (
                (lambda files: filter(exists, files))
                if check_existence
                else (lambda f: f)
            )(p.stdout.splitlines())
        )
    else:
        e = p.stderr.rstrip()
        logging.error(e)
        raise CalledProcessError(p.returncode, cmd, p.stdout.rstrip(), e)


def get_tracked_dirs(path: str = ".", tree_ish: str = "HEAD") -> list[str]:
    def add_dot(dir: str) -> str:
        return "." if dir == "" else dir

    return list(
        dict.fromkeys(
            map(lambda f: add_dot(dirname(f)), get_tracked_files(path, tree_ish))
        )
    )


def get_git_dir() -> str:
    """
    Get the path to the git directory.

    Raises:
        FileNotFoundError: If a git repository cannot be found.
    """
    if "GIT_DIR" in environ:
        return environ["GIT_DIR"]
    else:
        work_tree = get_work_tree_without_config()
        if work_tree is None:
            raise FileNotFoundError("Unable to find a git repository.")
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


def get_work_tree() -> str:
    """
    Get the path to the work tree for the git directory.

    Raises:
        FileNotFoundError: If a git repository cannot be found.
    """
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
            raise FileNotFoundError("Unable to find a git repository.")
    else:
        return work_tree
