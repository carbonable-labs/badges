// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

// Project dependencies
from openzeppelin.introspection.erc165.library import ERC165

// Local dependencies
from src.utils.metadata.library import Metadata

const IERC5192_ID = 0xb45a3c0e;

//
// Events
//

// @notice Emitted when a token id is locked for transfer.
// @param token_id The token id that was locked.
@event
func Locked(token_id: Uint256) {
}

// @notice Emitted when a token id is unlocked for transfer.
// @param token_id The token id that was unlocked.
@event
func Unlocked(token_id: Uint256) {
}

//
// Storage
//

@storage_var
func CarbonableBadge_unlocked(id: Uint256) -> (unlocked: felt) {
}

@storage_var
func CarbonableBadge_name() -> (name: felt) {
}

namespace CarbonableBadge {
    //
    // Initializer
    //

    // @notice Initialize the contract with the given uri and name.
    // @param uri_len The URI array length.
    // @param uri The URI characters as a felt array.
    // @param name The name of the badge collection.
    func initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(uri_len: felt, uri: felt*, name: felt) {
        Metadata.set_uri(uri_len, uri);
        ERC165.register_interface(IERC5192_ID);
        CarbonableBadge_name.write(name);
        return ();
    }

    //
    // Getters
    //

    func uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(id: Uint256) -> (uri_len: felt, uri: felt*) {
        let (uri_len: felt, uri: felt*) = Metadata.token_uri(id);
        return (uri_len=uri_len, uri=uri);
    }

    func contract_uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }() -> (uri_len: felt, uri: felt*) {
        let (uri_len: felt, uri: felt*) = Metadata.contract_uri();
        return (uri_len=uri_len, uri=uri);
    }

    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        let (name) = CarbonableBadge_name.read();
        return (name,);
    }

    func locked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: Uint256) -> (
        is_locked: felt
    ) {
        // [Check] Uint256 compliance
        with_attr error_message("CarbonableBadge: id is not a valid Uint256") {
            uint256_check(id);
        }

        let (is_unlocked) = CarbonableBadge_unlocked.read(id);
        return (1 - is_unlocked,);
    }

    //
    // Externals
    //

    func set_uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(uri_len: felt, uri: felt*) {
        Metadata.set_uri(uri_len, uri);
        return ();
    }

    func set_locked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        id: Uint256
    ) -> () {
        // [Check] Uint256 compliance
        with_attr error_message("CarbonableBadge: id is not a valid Uint256") {
            uint256_check(id);
        }

        CarbonableBadge_unlocked.write(id, FALSE);
        Locked.emit(id);

        return ();
    }

    func set_unlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        id: Uint256
    ) -> () {
        // [Check] Uint256 compliance
        with_attr error_message("CarbonableBadge: id is not a valid Uint256") {
            uint256_check(id);
        }

        CarbonableBadge_unlocked.write(id, TRUE);
        Unlocked.emit(id);

        return ();
    }

    //
    // Internals
    //

    func assert_unlocked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        id: Uint256
    ) -> () {
        // [Check] Uint256 compliance
        with_attr error_message("CarbonableBadge: id is not a valid Uint256") {
            uint256_check(id);
        }

        // [Check] Token is unlocked
        let (is_locked) = locked(id);
        with_attr error_message("CarbonableBadge: transfer is locked") {
            assert is_locked = FALSE;
        }
        return ();
    }

    func assert_unlocked_batch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ids_len: felt, ids: Uint256*
    ) -> () {
        _assert_unlocked_iter(ids_len=ids_len, ids=ids);
        return ();
    }

    func _assert_unlocked_iter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ids_len: felt, ids: Uint256*
    ) -> () {
        // [Check] Stop criteria
        if (ids_len == 0) {
            return ();
        }

        // [Check] Token is unlocked
        assert_unlocked([ids]);
        _assert_unlocked_iter(ids_len=ids_len - 1, ids=ids + 1);

        return ();
    }
}
