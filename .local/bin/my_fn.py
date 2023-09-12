from inspect import isfunction, getmodule, stack


def is_global_user_fn(name: str) -> bool:
    caller_frame = stack()[1][0]
    caller_globals = caller_frame.f_globals
    if name in caller_globals:
        caller_module = getmodule(caller_frame)
        if caller_module is not None:
            fn = eval(name, caller_globals, None)
            fn_module = getmodule(fn)
            if fn_module is not None:
                return isfunction(fn) and (fn_module == caller_module)
            else:
                return False
        else:
            return False
    else:
        return False
