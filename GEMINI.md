# TiKV Project Context & Instructions

TiKV is an open-source, distributed, and transactional key-value database. It provides transactional APIs with ACID compliance, built in Rust and powered by the Raft consensus algorithm. It is a graduated project of the Cloud Native Computing Foundation (CNCF).

## Project Overview

- **Core Technologies:** Rust (Nightly toolchain), Raft consensus, RocksDB storage engine, gRPC.
- **Key Features:** Geo-replication, horizontal scalability (100+ TBs), consistent distributed transactions (Percolator model), and coprocessor support for distributed computing.
- **Architecture:** 
    - **Placement Driver (PD):** The cluster manager (metadata, load balancing).
    - **Store:** Local storage (RocksDB).
    - **Region:** Basic unit of data movement and replication (Raft groups).
    - **Node:** Physical node containing one or more stores.

## Directory Structure

- `src/`: Main TiKV server source code.
    - `src/coprocessor/`: TiDB push-down request handling (table/index scans, aggregation).
    - `src/storage/`: Transaction and MVCC storage layer.
    - `src/server/`: gRPC server and service implementations.
- `components/`: Modular components and libraries (TiKV favors modularization).
    - `components/raftstore/`: Raft consensus and region management.
    - `components/pd_client/`: Client for interacting with PD.
    - `components/engine_traits/`: Storage engine abstraction.
    - `components/cdc/`: Change Data Capture.
    - `components/backup/`: Backup and restore functionality.
- `cmd/`: Binary entry points.
    - `cmd/tikv-server/`: Main server binary.
    - `cmd/tikv-ctl/`: Control utility.
- `tests/`: Integration and failpoint tests.
- `scripts/`: Development and CI scripts.

## Building and Running

### Prerequisites
- Rust (Nightly), `make`, `cmake`, `protoc`, `g++`/`clang`.

### Key Commands
- **Build Development:** `make build`
- **Build Release:** `make release`
- **Quick Check:** `cargo check --all`
- **Run Local Cluster:** `docker-compose up -d` (requires Docker).
- **Run Single Instance:** Requires a running PD instance. Use `tikv-server --pd-endpoints="<PD_URL>"`.

## Development & Testing

### Code Quality
- **Full Dev Check:** `make dev` (Run this before submitting any PR. Includes format, clippy, and tests).
- **Format:** `make format`
- **Lint:** `make clippy` (Always use the Makefile rule as it contains specific configurations).

### Testing
- **Run All Tests:** `make test`
- **Run with Nextest:** `make test_with_nextest` (Faster execution).
- **Run Specific Test:** `./scripts/test $TESTNAME -- --nocapture` or `env EXTRA_CARGO_ARGS=$TESTNAME make test`.
- **Docker Tests:** `make docker_test`

## Contribution Guidelines & Conventions

### Pull Request Rules
- **PR Title Format:** `module: description` or `module1, module2: description`. Use `*: description` for repository-wide changes.
- **Issue Linking:** PR descriptions must include `Issue Number: close #xxx` or `Issue Number: ref #xxx`.
- **Commit Signing:** All commits must be signed off for DCO: `git commit -s -m "message"`.
- **PR Template:** Follow the template at `.github/pull_request_template.md`.

### Coding Standards
- **Modularization:** When adding new logic, consider if it should be a new crate in `components/` rather than adding to `src/`.
- **Error Handling:** Use `thiserror` and `anyhow` as established in the project.
- **Logging:** Use `slog` with the provided wrappers in `log_wrappers`.
- **Performance:** Be mindful of the performance-critical path (see `PERFORMANCE_CRITICAL_PATH.md` for details).

## Useful Documentation
- [TiKV Documentation](https://tikv.org/docs/latest/concepts/overview/)
- [Deep Dive TiKV](https://tikv.org/deep-dive/introduction/)
- [Contributing Guide](./CONTRIBUTING.md)
- [Coprocessor Design](./src/coprocessor/README.md) (if available)
