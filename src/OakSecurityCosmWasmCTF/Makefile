all: fmt fix clippy test

fmt:
	cd 01-* && cargo fmt
	cd 02-* && cargo fmt
	cd 03-* && cargo fmt
	cd 04-* && cargo fmt
	cd 05-* && cargo fmt

fix:
	cd 01-* && cargo fix
	cd 02-* && cargo fix
	cd 03-* && cargo fix
	cd 04-* && cargo fix
	cd 05-* && cargo fix

clippy:
	cd 01-* && cargo clippy
	cd 02-* && cargo clippy
	cd 03-* && cargo clippy
	cd 04-* && cargo clippy
	cd 05-* && cargo clippy -- --allow clippy::no_effect

test:
	cd 01-* && cargo test
	cd 02-* && cargo test --release
	cd 03-* && cargo test
	cd 04-* && cargo test
	cd 05-* && cargo test
