#!/usr/bin/env python3.6
import glob
from multiprocessing.dummy import Pool
import os
import shutil
import subprocess
import sys
import time


def format_error(text):
    return '\033[31m[error]\033[0m %s' % text


def format_success(text):
    return '\033[32m[success]\033[0m %s' % text


def format_info(text):
    """..., how many for our boys in blue?"""
    return '\033[34m%s\033[0m' % text


def get_header_function(terminal_size):
    def h1(text):
        return ('{:=^%d}' % terminal_size).format(' %s ' % text)
    return h1


def get_test_files():
    return glob.glob("test/data/*.py")


def run(interpreter, filename):
    try:
        with open(os.devnull, 'w') as FNULL:
            return subprocess.check_output(
                [interpreter, filename],
                stderr=FNULL,
            )
    except subprocess.CalledProcessError as e:
        return e.args[0]


def compare_interpreters(filename):
    epython = run('./epython', filename)
    cpython = run('python3.6', filename)
    formatf = format_success if epython == cpython else format_error
    passage = filename.split('/')  # 7 letter synonym for path, so they align
    print(formatf(
        '%s/%s' % (
            '/'.join(passage[:-1]),
            format_info(passage[-1]),
        )
    ))
    return epython != cpython


def main():
    terminal_size = shutil.get_terminal_size().columns
    h1 = get_header_function(terminal_size)
    print(h1('building epython'))
    mix_process = subprocess.run(['mix', 'escript.build'])

    if mix_process.returncode != 0:
        print(format_error('epython failed to build'))
        sys.exit(1)

    print(h1('running comparison tests'))
    t1 = time.time()
    with Pool() as dont_pee_in_it:
        n = sum(dont_pee_in_it.map(compare_interpreters, get_test_files()))
    test_time = round(time.time() - t1, 2)
    print(h1('%s failed in %s seconds' % (n, test_time)))


if __name__ == '__main__':
    main()
