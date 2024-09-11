pragma solidity ^0.8.25;

import {Animal} from "./Animal.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract ZOO is Pausable {
    uint256 public isSolved;
    AnimalWrapper[] public animals;

    struct AnimalWrapper {
        Animal animal;
        uint256 counter;
    }

    uint256 constant ADD = 0x10;
    uint256 constant EDIT = 0x20;
    uint256 constant DEL = 0x30;

    uint256 constant EDIT_NAME = 0x21;
    uint256 constant EDIT_TYPE = 0x22;

    uint256 constant TRACK_MAX = 0x100;

    constructor() {
        animals.push(AnimalWrapper(new Animal("PANDA", "PND"), 0));
        animals.push(AnimalWrapper(new Animal("TIGER", "TGR"), 0));
        animals.push(AnimalWrapper(new Animal("HORSE", "HRS"), 0));
        animals.push(AnimalWrapper(new Animal("ZIBRA", "ZBR"), 0));
        animals.push(AnimalWrapper(new Animal("HIPPO", "HPO"), 0));
        animals.push(AnimalWrapper(new Animal("LION", "LON"), 0));
        animals.push(AnimalWrapper(new Animal("BEAR", "BAR"), 0));
        animals.push(AnimalWrapper(new Animal("WOLF", "WLF"), 0));
        animals.push(AnimalWrapper(new Animal("ELEPHANT", "ELP"), 0));
        animals.push(AnimalWrapper(new Animal("RHINO", "RNO"), 0));

        // The ZOO is not opened yet :(
        _pause();
    }

    function commit(bytes memory data) internal whenNotPaused {
        assembly {
            let counter := 0
            let length := mload(data)

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let idx
                let name

                let memPtr := mload(0x40)

                let ptr := mload(add(add(data, 0x20), counter))
                idx := mload(ptr)
                name := add(ptr, 0x20)
                let name_length := mload(name)
                counter := add(counter, 0x20)

                mstore(0x00, animals.slot)
                let slot_hash := keccak256(0x00, 0x20)
                let animal_addr := sload(add(slot_hash, mul(2, idx)))
                let animal_counter := sload(add(add(slot_hash, mul(2, idx)), 1))

                if gt(animal_counter, 50) { revert(0, 0) }

                mstore(memPtr, shl(0xe0, 0x1436163e))
                mstore(add(memPtr, 0x4), caller())

                pop(call(gas(), animal_addr, 0x00, memPtr, 0x24, memPtr, 0x00))

                mstore(memPtr, shl(0xe0, 0x61bc221a))
                pop(staticcall(gas(), animal_addr, memPtr, 0x20, memPtr, 0x20))

                let animal_count := sub(mload(memPtr), 0x1)

                mstore(memPtr, shl(0xe0, 0xfe55932a))
                mstore(add(memPtr, 0x4), animal_count)
                mstore(add(memPtr, 0x24), 0x40)
                mstore(add(memPtr, 0x44), name_length)
                mcopy(add(memPtr, 0x64), name, name_length)

                pop(call(gas(), animal_addr, 0x00, memPtr, 0x84, memPtr, 0x00))

                sstore(add(add(slot_hash, mul(2, idx)), 1), add(animal_counter, 1))
            }
        }
    }

    fallback() external payable {
        function(bytes memory)[] memory functions = new function(
            bytes memory
        )[](1);
        functions[0] = commit;

        bytes memory local_animals;
        assembly {
            let arr := mload(0x40)
            let size := calldatasize()
            mstore(arr, size)
            let size_align := add(add(size, sub(0x20, mod(size, 0x20))), 0x20)
            mstore(0x40, add(arr, size_align))
            calldatacopy(add(arr, 0x20), 0, size)

            local_animals := mload(0x40)
            mstore(0x40, add(local_animals, 0x120))

            for { let i := 0 } lt(i, size) {} {
                let op := mload(add(add(arr, 0x20), i))
                op := shr(0xf8, op)
                i := add(i, 1)

                switch op
                case 0x10 {
                    let idx := mload(add(add(arr, 0x20), i))
                    idx := shr(0xf8, idx)
                    i := add(i, 1)

                    if gt(idx, 7) { revert(0, 0) }

                    let name_length := mload(add(add(arr, 0x20), i))
                    name_length := shr(0xf0, name_length)
                    i := add(i, 2)

                    let animal_index := mload(add(add(arr, 0x20), i))
                    animal_index := shr(0xf0, animal_index)
                    i := add(i, 2)

                    let temp := mload(0x40)
                    mstore(temp, animal_index)
                    mcopy(add(temp, 0x40), add(add(arr, 0x20), i), name_length)
                    i := add(i, name_length)

                    name_length := add(name_length, sub(0x20, mod(name_length, 0x20)))

                    mstore(add(temp, 0x20), name_length)
                    mstore(0x40, add(temp, add(name_length, 0x40)))

                    mstore(add(add(local_animals, 0x20), mul(0x20, idx)), temp)

                    let animals_count := mload(local_animals)
                    mstore(local_animals, add(animals_count, 1))
                }
                case 0x20 {
                    let idx := mload(add(add(arr, 0x20), i))
                    idx := shr(0xf8, idx)
                    i := add(i, 1)

                    if gt(idx, 7) { revert(0, 0) }

                    let offset := add(add(local_animals, 0x20), mul(0x20, idx))
                    let temp := mload(offset)

                    let edit_type := mload(add(add(arr, 0x20), i))
                    edit_type := shr(0xf8, edit_type)
                    i := add(i, 1)

                    switch edit_type
                    case 0x21 {
                        let name_length := mload(add(add(arr, 0x20), i))
                        name_length := shr(0xf0, name_length)
                        i := add(i, 2)

                        mcopy(add(temp, 0x40), add(add(arr, 0x20), i), name_length)
                    }
                    case 0x22 {
                        let new_type := mload(add(add(arr, 0x20), i))
                        new_type := shr(0xf0, new_type)
                        i := add(i, 2)

                        mstore(add(temp, 0x20), new_type)
                    }
                }
                case 0x30 {
                    let idx := mload(add(add(arr, 0x20), i))
                    idx := shr(0xf8, idx)
                    i := add(i, 1)

                    if gt(idx, 7) { revert(0, 0) }

                    let offset := add(add(local_animals, 0x20), mul(0x20, idx))
                    let temp := mload(offset)

                    let copy_size := sub(0x100, mul(0x20, idx))
                    mcopy(offset, add(offset, 0x20), copy_size)

                    let animals_count := mload(local_animals)
                    animals_count := sub(animals_count, 1)
                    mstore(local_animals, animals_count)
                }
                default { break }
            }
        }
        functions[0](local_animals);
    }

    receive() external payable {}
}
