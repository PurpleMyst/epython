# Thank you to github.com/Akuli for this code!
# I find it amazing how it manages to run even with how simple the interperter
# is currently.

pi = 3.141592653589793

def round(x):
    return (x + 0.5)//1

def fmod(x, m):
    if x >= m:
        return fmod(x-m, m)
    if x < 0:
        return fmod(x+m, m)
    return x

def sin(x):
    x = fmod(x, 2*pi)
    if x > pi:
        return -sin(2*pi - x)
    if x > pi/2:
        return sin(pi-x)
    return x - x**3/(1*2*3) + x**5/(1*2*3*4*5) - x**7/(1*2*3*4*5*6*7)

def range_for(func, start, stop):
    if start < stop:
        func(start)
        range_for(func, start+1, stop)

def repeat_string(s, howmanytimes):
    if howmanytimes <= 1:
        return s
    return s + repeat_string(s, howmanytimes-1)

def put_char(math_x, char):
    display_x = round(math_x*20 + 21)
    return repeat_string('\u001b[1C', display_x) + char + '\r'

def iteration(linenumber):
    x = linenumber/10
    line = ''
    line = line + put_char(0, '|')
    line = line + put_char(-1, '.')
    line = line + put_char(1, '.')
    line = line + put_char(sin(x), 'o')
    print(line)

range_for(iteration, 0, 80)
