// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

// Local dependencies
from src.minter.library import CarbonableMinter

//
// Functions
//

func setup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{
        # Load config
        import sys
        sys.path.append('.')
        from tests import load
        load("./tests/units/minter/config.yml", context)
    %}

    return ();
}

func prepare{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(contract_owner: felt, public_key: felt, badge_contract_address: felt, proxy_admin: felt) -> () {
    alloc_locals;

    // Instantiate minter
    CarbonableMinter.initializer(public_key, badge_contract_address);

    return ();
}
