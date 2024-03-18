import asyncio


async def run(cmd: list[str], check: bool = False, text: bool = False):
    p = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await p.communicate()
    p.stdout, p.stderr = (  # pyright: ignore [reportAttributeAccessIssue]
        (stdout.decode(), stderr.decode()) if text else (stdout, stderr)
    )
    if p.returncode == 0:
        return p
    else:
        if check:
            raise Exception(
                f"Command {cmd} failed with exit code {p.returncode}, stderr: {stderr.decode()}"
            )
        else:
            return p
