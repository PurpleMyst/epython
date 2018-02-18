def bubble_sort(xs):
    swapped = False
    i = 0
    l = len(xs)

    for x in xs:
        if i == l - 1:
            break

        if x > xs[i + 1]:
            xs[i], xs[i + 1] = xs[i + 1], x
            swapped = True
            break

        i += 1

    if swapped:
        bubble_sort(xs)


example = [54, 26, 93, 17, 77, 31, 44, 55, 20]
print(example)
bubble_sort(example)
print(example)
