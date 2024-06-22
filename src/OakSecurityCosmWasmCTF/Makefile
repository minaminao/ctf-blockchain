all: fmt fix clippy test

fmt:
	cd 01-* && cargo fmt
	cd 02-* && cargo fmt
	cd 03-* && cargo fmt
	cd 04-* && cargo fmt
	cd 05-* && cargo fmt
	cd 06-* && cargo fmt
	cd 07-* && cargo fmt

fix:
	cd 01-* && cargo fix --allow-dirty --allow-staged
	cd 02-* && cargo fix --allow-dirty --allow-staged
	cd 03-* && cargo fix --allow-dirty --allow-staged
	cd 04-* && cargo fix --allow-dirty --allow-staged
	cd 05-* && cargo fix --allow-dirty --allow-staged
	cd 06-* && cargo fix --allow-dirty --allow-staged
	cd 07-* && cargo fix --allow-dirty --allow-staged

clippy:
	cd 01-* && cargo clippy
	cd 02-* && cargo clippy
	cd 03-* && cargo clippy
	cd 04-* && cargo clippy
	cd 05-* && cargo clippy -- --allow clippy::no_effect
	cd 06-* && cargo clippy
	cd 07-* && cargo clippy

test:
	cd 01-* && cargo test
	cd 02-* && cargo test --release
	cd 03-* && cargo test
	cd 04-* && cargo test
	cd 05-* && cargo test
	cd 06-* && cargo test
	cd 07-* && cargo test
