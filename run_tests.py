import subprocess
import os


def print_success(text):
    print('\033[32m[success]\033[0m', text)


def print_error(text):
    print('\033[31m[error]\033[0m', text)


def get_test_files():
    for filename in os.listdir('test/data'):
        if filename.endswith('.py'):
            yield 'test/data/' + filename


def run(interpreter, filename):
    try:
        with open(os.devnull, 'w') as FNULL:
            return subprocess.check_output(
                [interpreter, filename],
                stderr=FNULL,
            )
    except subprocess.CalledProcessError as e:
        return e.args[0]


def main():
    subprocess.call(['mix', 'escript.build'])
    for filename in get_test_files():
        epython = run('./epython', filename)
        cpython = run('python3.6', filename)
        if epython == cpython:
            print_success(filename)
        else:
            print_error(filename)


if __name__ == '__main__':
    main()
