use common::flash_loan::{Config, FlashLoanState};
use cw_storage_plus::Item;

pub const CONFIG: Item<Config> = Item::new("config");
pub const FLASH_LOAN: Item<FlashLoanState> = Item::new("flash_loan");
