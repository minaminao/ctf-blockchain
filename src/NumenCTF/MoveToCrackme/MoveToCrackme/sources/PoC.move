script {
    use 0x3::encode;
    use std::debug;

    fun test_script(account: signer) {

        // ===========================MoveToCrackMe==========================================================
        // Write the PoC here to decrypt the encrypted_steam :) get the right crackme stream. Good luck.
        // ==================================================================================================

        let buffer1: vector<u64> = vector[4, 6, 26, 10, 8, 16, 26, 26, 21, 18, 0, 23, 2, 6, 10, 14, 12, 5, 15, 5, 14, 19, 4, 6, 11, 1, 21, 3, 12, 12, 22, 15, 4, 0, 1, 14, 5, 5, 11, 11, 19, 0, 28, 11, 10, 19, 8, 1, 11, 12, 1, 21, 21, 9, 2, 3, 12, 15, 12, 3, 3, 11, 27];
        let buffer2: vector<u64> = vector[6, 12, 2, 10, 6, 23, 4, 21, 3];
        encode::ctf_decrypt(buffer1, buffer2, account)
    }
}

