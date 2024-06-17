use common::mock_arb::Config;
use cw_storage_plus::Item;

pub const CONFIG: Item<Config> = Item::new("config");
