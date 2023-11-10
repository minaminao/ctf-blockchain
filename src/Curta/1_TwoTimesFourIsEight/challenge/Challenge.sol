// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../general/IPuzzle.sol";

/// @title 2 × 4 = 8
/// @custom:subtitle Sodoku
/// @author fiveoutofnine
/// @notice A modified version of the classic Sodoku puzzle, for an 8 × 8 grid.
/// As usual, each row and column must contain [1, ..., 8] exactly once.
/// However, unlike in regular Sodoku, we now check for 2 × 4 subgrids, rather
/// than 3 × 3 subgrids.
contract TwoTimesFourIsEight is IPuzzle {
    /// @notice A mapping of from indices to which checks must be performed at
    /// that index.
    /// @dev We reserve 3 bits for each check as follows:
    ///     * 0th bit is `1`: check subgrid;
    ///     * 1st bit is `1`: check column;
    ///     * 2nd bit is `1`: check row.
    ///
    /// For clarity, the following table lays out the bitpacked values:
    ///             | Index | Row     | Column  | Subgrid | Value |
    ///             |-------+---------+---------+---------+-------|
    ///             |     0 |       1 |       1 |       1 | 0b111 |
    ///             |     1 |       0 |       1 |       0 | 0b010 |
    ///             |     2 |       0 |       1 |       0 | 0b010 |
    ///             |     3 |       0 |       1 |       0 | 0b010 |
    ///             |     4 |       0 |       1 |       1 | 0b011 |
    ///             |     5 |       0 |       1 |       0 | 0b010 |
    ///             |     6 |       0 |       1 |       0 | 0b010 |
    ///             |     7 |       0 |       1 |       0 | 0b010 |
    ///             |     8 |       1 |       0 |       0 | 0b100 |
    ///             |    16 |       1 |       0 |       1 | 0b101 |
    ///             |    20 |       0 |       0 |       1 | 0b001 |
    ///             |    24 |       1 |       0 |       0 | 0b100 |
    ///             |    32 |       1 |       0 |       1 | 0b101 |
    ///             |    36 |       0 |       0 |       1 | 0b001 |
    ///             |    40 |       1 |       0 |       0 | 0b100 |
    ///             |    48 |       1 |       0 |       1 | 0b101 |
    ///             |    52 |       0 |       0 |       1 | 0b001 |
    ///             |    56 |       1 |       0 |       0 | 0b100 |
    uint256 private constant CHECKS = 0x400010005000000040001000500000004000100050000000422232227;

    /// @notice A bitpacked value that indicates how many bits to shift by to
    /// get to the next value in the row.
    /// @dev We reserve 6 bits for each value, and the following are packed
    // left-to-right: `[4, 4, 4, 4, 4, 4, 4, 4]`.
    uint256 private constant ROW_SHIFTS = 0x104104104104;

    /// @notice A bitpacked value that indicates how many bits to shift by to
    /// get to the next value in the column.
    /// @dev We reserve 6 bits for each value, and the following are packed
    // left-to-right: `[32, 32, 32, 32, 32, 32, 32, 32]`.
    uint256 private constant COL_SHIFTS = 0x820820820820;

    /// @notice A bitpacked value that indicates how many bits to shift by to
    /// get to the next value in the 2 × 4 subgrid.
    /// @dev We reserve 6 bits for each value, and the following are packed
    // left-to-right: `[4, 4, 4, 20, 4, 4, 4, 4]`.
    uint256 private constant SUBGRID_SHIFTS = 0x104104504104;

    /// @notice A bitmap to denote that each of [1, ..., 8] has been seen.
    /// @dev Bits 1-8 should be set to 1, with everything else set to 0 (i.e.
    /// `0b111111110 = 0xFE`).
    uint256 private constant FILLED_BITMAP = 0x1FE;

    /// @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return unicode"2 × 4 = 8";
    }

    /// @inheritdoc IPuzzle
    function generate(address _seed) external pure returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_seed)));
        uint256 puzzle;

        // We use this to keep track of which indices [0, ..., 63] have been
        // filled. See the next comment for why the value is initialized to
        // `1 << 64`.
        uint256 bitmap = 1 << 64;
        // Note that the bitmap only intends on reserving bits 0-63 to represent
        // the slots that have been filled. Thus, if we set `index` to 64, it
        // is a sentinel value that will always yield 0 when using it to
        // retrieve from the bitmap.
        uint256 index = 64;
        // We fill the puzzle randomly with 1 of [1, ..., 8]. This way, every
        // puzzle is solvable.
        for (uint256 i = 1; i < 9;) {
            // We have exhausted the seed, so stop iterating.
            if (seed == 0) break;

            // Loop through until we find an unfilled index.
            while ((bitmap >> index) & 1 == 1 && seed != 0) {
                // Retrieve 6 random bits from `seed` to determine which index
                // to fill.
                index = seed & 0x3F;
                seed >>= 6;
            }
            // Set the bit in the bitmap to indicate that the index has
            // been filled.
            bitmap |= 1 << index;

            // Place the number into the slot that was just filled.
            puzzle |= (i << (index << 2));
            index = 64;
            unchecked {
                ++i;
            }
        }

        return puzzle;
    }

    /// @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external pure returns (bool) {
        // Iterate through the puzzle.
        for (uint256 index; index < 256;) {
            // Check that the starting position is included in the solution.
            if (_start & 0xF != 0 && _start & 0xF != _solution & 0xF) {
                return false;
            }

            // Retrieve how many checks to perform.
            uint256 checks = (CHECKS >> index) & 7;
            if (checks & 4 == 4 && !check(_solution, ROW_SHIFTS)) return false;
            if (checks & 2 == 2 && !check(_solution, COL_SHIFTS)) return false;
            if (checks & 1 == 1 && !check(_solution, SUBGRID_SHIFTS)) {
                return false;
            }

            _start >>= 4;
            _solution >>= 4;
            unchecked {
                index += 4;
            }
        }

        return true;
    }

    /// @notice Checks whether a row, column, or box is filled in a valid way.
    /// @param _shifted The puzzle shifted to the index it should start checking
    /// from.
    /// @param _shifts A bitpacked value that indicates how many bits to shift
    /// by after each iteration in the loop.
    /// @return Whether the check is valid.
    function check(uint256 _shifted, uint256 _shifts) internal pure returns (bool) {
        uint256 shifted = _shifted;
        // Used to keep track of which numbers [1, ..., 8] have been seen.
        uint256 bitmap;

        while (_shifts != 0) {
            // Set the bit in the bitmap to indicate that the number has been
            // seen.
            bitmap |= 1 << (shifted & 0xF); // `shifted & 0xF` reads the number.
            // Retrieve 6 bits from `_shifts` to determine how many bits to
            // shift the puzzle by.
            shifted >>= (_shifts & 0x3F);
            _shifts >>= 6;
        }

        return bitmap == FILLED_BITMAP;
    }
}
