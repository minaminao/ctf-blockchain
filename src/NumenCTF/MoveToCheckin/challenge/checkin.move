module checkin::checkin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;

    struct Flag has copy, drop {
        user: address,
        flag: bool
    }

    fun init(ctx: &mut TxContext) {
    }

    public entry fun HelloHackers(buffer: vector<u8>,ctx: &mut TxContext) {
        let h=buffer;
        let value=b"hello";
        if(h == value){
            event::emit(Flag {
                user: tx_context::sender(ctx),
                flag: true
            });
        }
    }
}
