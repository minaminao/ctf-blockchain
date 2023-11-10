import neko.algo.sudoku as sudoku

def puzzle_to_2d_array(puzzle):
    # Convert the puzzle to a binary string
    puzzle_bin = format(puzzle, '0256b')

    # Split the binary string into 4-bit chunks
    cells = [puzzle_bin[i:i+4] for i in range(0, len(puzzle_bin), 4)]

    # Convert each 4-bit chunk to an integer
    cells = [int(cell, 2) for cell in cells]

    # Group the cells into rows to form a 2D array
    puzzle_2d = [cells[i:i+8] for i in range(0, len(cells), 8)]

    return puzzle_2d

def array_to_puzzle(array):
    # Convert the 2D array to a 1D array
    cells = [cell for row in array for cell in row]

    # Convert each cell to a 4-bit binary string
    cells = [format(cell, '04b') for cell in cells]

    # Join the 4-bit binary strings into a single binary string
    puzzle_bin = ''.join(cells)

    # Convert the binary string to an integer
    puzzle = int(puzzle_bin, 2)

    return puzzle


puzzle = 1961977486345643953169794982364451687158713042345442410496
instance = puzzle_to_2d_array(puzzle)
assert array_to_puzzle(instance) == puzzle

answer = array_to_puzzle(sudoku.solve(instance, 1, N=8, MI=2, MJ=4)[0])

print(answer)

