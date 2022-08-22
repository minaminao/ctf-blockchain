%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@storage_var
func _solution() -> (res : felt):
end

@external
func solve{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(solution : felt):
    _solution.write(solution)
    return ()
end

@view
func solution{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (solution : felt):
    let (solution) = _solution.read()
    return (solution)
end