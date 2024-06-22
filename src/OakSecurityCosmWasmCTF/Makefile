all: fmt test

fmt:
	cd 01-* && cargo fmt
	cd 02-* && cargo fmt
	cd 03-* && cargo fmt
	cd 04-* && cargo fmt
	cd 05-* && cargo fmt

test:
	cd 01-* && cargo test
	cd 02-* && cargo test --release
	cd 03-* && cargo test
	cd 04-* && cargo test
	cd 05-* && cargo test
