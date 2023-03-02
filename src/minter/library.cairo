// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import SignatureBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

// Local dependencies
from src.interfaces.badge import ICarbonableBadge

//
// Storage
//

@storage_var
func CarbonableMinter_signer_public_key() -> (signer_public_key: felt) {
}

@storage_var
func CarbonableMinter_badge_contract_address() -> (badge_contract_address: felt) {
}

namespace CarbonableMinter {
    //
    // Initializer
    //

    // @notice Initialize the contract with the given signer public key and badge contract address.
    // @param signer_public_key The signer public key.
    // @param badge_contract_address The badge contract address.
    func initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(signer_public_key: felt, badge_contract_address: felt) {
        CarbonableMinter_signer_public_key.write(signer_public_key);
        CarbonableMinter_badge_contract_address.write(badge_contract_address);
        return ();
    }

    //
    // Getters
    //

    // @notice Return the public key of the signer.
    // @return signer_public_key The signer public key.
    func getSignerPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (signer_public_key: felt) {
        let (signer_public_key: felt) = CarbonableMinter_signer_public_key.read();
        return (signer_public_key,);
    }

    // @notice Return the address of the badge contract.
    // @return badge_contract_address The badge contract address.
    func getBadgeContractAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (badge_contract_address: felt) {
        let (badge_contract_address: felt) = CarbonableMinter_badge_contract_address.read();
        return (badge_contract_address,);
    }

    //
    // Externals
    //

    // @notice Claim a badge of the given type.
    // @param badge_type The badge type.
    func claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*}(
        badge_type : felt,
    ) -> () {
        alloc_locals;

        let (caller_address) = get_caller_address();
        let (badge_contract_address) = CarbonableMinter_badge_contract_address.read();

        // Check if the NFT hasn't already been minted
        let (balance) = ICarbonableBadge.balanceOf(badge_contract_address, caller_address, Uint256(badge_type, 0));
        assert balance = Uint256(0, 0);

        let (data) = alloc();
        
        ICarbonableBadge.mint(badge_contract_address, caller_address, Uint256(badge_type, 0), Uint256(1, 0), 0, data);
        return ();
    }

    // @notice Set the public key of the signer for mintBadge transactions.
    // @param new_signer_public_key The new signer public key.
    func setSignerPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_signer_public_key: felt
    ) -> () {
        CarbonableMinter_signer_public_key.write(new_signer_public_key);
        return ();
    }

    // @notice Set the address of the badge contract.
    // @param new_badge_contract_address The new badge contract address.
    func setBadgeContractAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_badge_contract_address: felt
    ) -> () {
        CarbonableMinter_badge_contract_address.write(new_badge_contract_address);
        return ();
    }

    // @notice Transfer ownership of the badge contract to a new owner.
    // @param newOwner The address of the new owner.
    func transferBadgeContractOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        newOwner: felt
    ) {
        let (badge_contract_address) = CarbonableMinter_badge_contract_address.read();
        ICarbonableBadge.transferOwnership(badge_contract_address, newOwner);
        return ();
    }

    //
    // Internals
    //

    func assert_valid_signature{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*}(
        message: (felt, felt),
        signature: (felt, felt),
    ) {
        let (signer_public_key) = CarbonableMinter_signer_public_key.read();
        let (messageHash) = hash2{hash_ptr=pedersen_ptr}(message[0], message[1]);
        // [Check] Signature is valid
        with_attr error_message("CarbonableMinter: invalid signature") {
            verify_ecdsa_signature(messageHash, signer_public_key, signature[0], signature[1]);
        }
        return ();
    }
}