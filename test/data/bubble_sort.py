def bubble_sort(xs):
    swapped = False

    for i in range(len(xs) - 1):
        if xs[i] > xs[i + 1]:
            xs[i], xs[i + 1] = xs[i + 1], xs[i]
            swapped = True

    if swapped:
        bubble_sort(xs)


example = [54, 26, 93, 17, 77, 31, 44, 55, 20]
bubble_sort(example)
print(example)
