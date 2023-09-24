"use strict";
var utils = mp.utils;
var msg = mp.msg;
if (String.prototype.trimEnd === undefined) {
    String.prototype.trimEnd = function () {
        return this.replace(/\s+$/, "");
    };
}
Array.prototype.remove = function (index) {
    var copy = this.slice();
    return [copy.splice(index, 1)[0], copy];
};
function sorted(list, key) {
    if (key === void 0) { key = function (x) {
        return x;
    }; }
    return list.slice().sort(function (a, b) {
        var keyA = key(a);
        var keyB = key(b);
        if (Array.isArray(keyA) && Array.isArray(keyB)) {
            for (var i = 0; i < keyA.length && i < keyB.length; i++) {
                if (keyA[i] < keyB[i]) {
                    return -1;
                }
                else if (keyA[i] > keyB[i]) {
                    return 1;
                }
            }
            if (keyA.length < keyB.length) {
                return -1;
            }
            else if (keyA.length === keyB.length) {
                return 0;
            }
            else {
                return 1;
            }
        }
        else {
            if (keyA < keyB) {
                return -1;
            }
            else if (keyA === keyB) {
                return 0;
            }
            else {
                return 1;
            }
        }
    });
}
function natsort(s, _nsRe, _digRe) {
    if (_nsRe === void 0) { _nsRe = /(\d+)/; }
    if (_digRe === void 0) { _digRe = /^\d+$/; }
    function isDigit(n) {
        return _digRe.test(n);
    }
    var splitList = s.split(_nsRe);
    if (splitList[0] === "") {
        splitList.shift();
    }
    if (splitList[splitList.length - 1] === "") {
        splitList.pop();
    }
    return splitList.map(function (text) {
        return isDigit(text) ? parseInt(text, 10) : text;
    });
}
function subprocess(args, check) {
    if (check === void 0) { check = false; }
    var p = mp.command_native({
        args: args,
        name: "subprocess",
        playback_only: false,
        capture_stdout: true,
    });
    if (check) {
        var status = p.status;
        if (status === 0) {
            return p;
        }
        else {
            throw new Error(p.stderr +
                "Command " +
                JSON.stringify(args) +
                " returned non-zero exit status " +
                JSON.stringify(status));
        }
    }
    else {
        return p;
    }
}
function keysToTable(keys, value) {
    if (value === void 0) { value = true; }
    var table = {}; //in js, object can only have string keys
    keys.forEach(function (key) {
        table[key] = value;
    });
    return table;
}
function splitExt(path) {
    var _a = utils.split_path(path), dir = _a[0], file = _a[1];
    var lastDotIndex = file.lastIndexOf(".");
    if (lastDotIndex === 0 || lastDotIndex == -1) {
        return [path, ""];
    }
    else {
        return [
            utils.join_path(dir, file.slice(0, lastDotIndex)),
            file.slice(lastDotIndex),
        ];
    }
}
function getMimetype(file) {
    var extension = splitExt(file)[1];
    var fileArgs = ["file", "-Lb", "--mime-type", file];
    var xdgArgs = ["xdg-mime", "query", "filetype", file];
    var args = extension in keysToTable([".ts", ".bak", ".txt", ".TXT"])
        ? fileArgs
        : xdgArgs;
    var str = subprocess(args, true).stdout.trimEnd();
    var mimeType = str.split("/");
    if (mimeType.length !== 2) {
        if (args === xdgArgs) {
            var newStr = subprocess(fileArgs, true).stdout.trimEnd();
            var newType = newStr.split("/");
            if (newType.length !== 2) {
                throw new Error(JSON.stringify(fileArgs) + " returns: " + newStr);
            }
            else {
                return newType;
            }
        }
        else {
            throw new Error(JSON.stringify(fileArgs) + " returns: " + str);
        }
    }
    else {
        return mimeType;
    }
}
function getFiles(dir) {
    var allowedTypes = ["video", "audio"];
    var allowedTypesTable = keysToTable(allowedTypes);
    var files = utils.readdir(dir, "files");
    return sorted(files.filter(function (file) {
        var mimeType = getMimetype(file);
        return mimeType[0] in allowedTypesTable;
    }), natsort);
}
function checkPlaylist(pl_count) {
    if (pl_count > 1) {
        msg.verbose("stopping: manually made playlist");
        return false;
    }
    else {
        return true;
    }
}
function fdCurrentEntryPos(files, file) {
    var current = files.indexOf(file);
    if (current === -1) {
        return null;
    }
    else {
        msg.trace("current file position in files: " + current);
        return current;
    }
}
function main() {
    var path = mp.get_property("path", "");
    var _a = utils.split_path(path), dir = _a[0], file = _a[1];
    msg.trace("dir: " + dir + ", file: " + file);
    var files = getFiles(dir);
    if (files.length === 0) {
        msg.verbose("no other files or directories in directory");
        return;
    }
    else {
        var current = fdCurrentEntryPos(files, file);
        if (current === null) {
            return;
        }
        else {
            files.remove(current)[1].forEach(function (file) {
                mp.commandv("loadfile", file, "append");
            });
            mp.commandv("playlist-move", 0, current + 1);
        }
    }
}
mp.register_event("start-file", function () {
    var pl_count = mp.get_property_number("playlist-count", 1);
    if (checkPlaylist(pl_count)) {
        main();
    }
    else {
        return;
    }
});
