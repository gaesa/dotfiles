#!/usr/bin/env python3
from sys import argv

from editor import open_with_emacs

open_with_emacs(argv[1:], allow_empty=True)
