# TiKV Development Context

## Project Overview

**TiKV** is an open-source, distributed, transactional key-value database powered by Rust and Raft. Originally created by PingCAP to complement TiDB, it's now a graduated CNCF project. TiKV provides:

- **Transactional APIs** with ACID compliance (not just key-value operations)
- **Horizontal scalability** to 100+ TBs of data
- **Geo-replication** using Raft consensus
- **Coprocessor support** for distributed computing
- **Snapshot isolation** and externally consistent distributed transactions

**Architecture**: Placement Driver (PD) manages the cluster → Stores (RocksDB) hold data → Regions (replicated via Raft) are the basic unit of data movement.

## Tech Stack

- **Primary Language**: Rust (nightly toolchain)
- **Storage Engine**: RocksDB (via rust-rocksdb bindings)
- **Consensus**: Raft (raft-rs implementation)
- **RPC**: gRPC (grpc-rs)
- **Build System**: Cargo + Makefile wrapper
- **Testing**: Rust test framework + integration tests

## Development Environment Setup

### Prerequisites

**Required Tools:**
- `git` - Version control
- `rustup` - Rust toolchain manager (project uses `nightly-2026-01-30`)
- `make` - Build automation
- `cmake` - Required for gRPC build
- `awk` - Text processing
- `protoc` - Protocol Buffer compiler (3.x+)
- C++ compiler - gcc 5+ or clang (for gRPC/RocksDB)

**Optional (platform-specific):**
- `llvm` + `clang` - Required for non-x86_64/aarch64 Linux/macOS platforms

### Quick Start

```bash
# Clone and enter repository
git clone https://github.com/tikv/tikv.git
cd tikv

# Rust toolchain auto-configures from rust-toolchain.toml
# Install required components
rustup component add rustfmt clippy rust-src rust-analyzer

# Build development version
make build

# Run all checks before PR submission
make dev
```

### Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Development build (debug, unoptimized) |
| `make release` | Optimized release build (uses `--release`) |
| `make dev` | Full development check: format + clippy + tests |
| `cargo check --all` | Fast type-check without compilation |
| `make clippy` | Run linter with TiKV-specific configuration |
| `make format` | Format code with rustfmt |

### Testing

```bash
# Run full test suite
make test

# Run specific test
./scripts/test $TESTNAME -- --nocapture

# Run with nextest (faster)
env EXTRA_CARGO_ARGS=$TESTNAME make test_with_nextest

# Run tests in Docker (isolated environment)
make docker_test
```

### Docker Development

```bash
# Get interactive shell in dev container
make docker_shell

# Run tests in container
make docker_test
```

## Code Organization

### Main Source (`/src/`)

```
src/
├── config/          # Configuration parsing and validation
├── coprocessor/     # TiDB push-down operations (scan, aggregation)
├── coprocessor_v2/  # V2 plugin system
├── import/          # SST file import
├── server/          # gRPC server, connections, services
└── storage/         # Transaction & MVCC layer
    ├── mvcc/        # Multi-Version Concurrency Control
    └── txn/         # Transaction processing
```

### Components (`/components/`) - 70+ modular crates

**Core Storage:**
- `engine_rocks/` - RocksDB implementation
- `engine_traits/` - Storage engine abstraction
- `raftstore/`, `raftstore-v2/` - Raft consensus & region management

**Transaction & Coprocessing:**
- `txn_types/` - Transaction type definitions
- `tidb_query_*` - SQL query processing (datatype, expr, executors, aggregators)
- `coprocessor_plugin_api/` - Plugin API

**Infrastructure:**
- `pd_client/` - Placement Driver client
- `keys/` - Key encoding/decoding
- `tikv_util/` - Common utilities
- `error_code/` - Error definitions
- `security/` - TLS & encryption

**Features:**
- `cdc/` - Change Data Capture
- `backup/`, `backup-stream/` - Backup & PITR
- `encryption/` - Data encryption at rest
- `external_storage/` - S3, GCS, Azure support
- `resource_control/` - Quota management

**Testing:**
- `test_*` - Test utilities and integration test helpers

### Binaries (`/cmd/`)

- `tikv-server/` - Main server binary
- `tikv-ctl/` - Control/debug utility

### Tests (`/tests/`)

- `benches/` - Benchmarks
- `failpoints/` - Failpoint tests
- `integrations/` - Integration tests

## Configuration

TiKV uses TOML configuration files. See `etc/config-template.toml` for comprehensive options.

**Key configuration areas:**
- `[log]` - Logging level, format, file rotation
- `[storage]` - Data directory, block cache
- `[server]` - Address, labels, status endpoint
- `[raftstore]` - Raft-specific settings
- `[pd]` - Placement Driver endpoints

**Runtime overrides** via CLI flags: `--addr`, `--data-dir`, `--pd-endpoints`, `--log-level`, etc.

## Development Conventions

### Code Style

- **Rust Edition**: 2021 (with 2024 style edition in rustfmt)
- **Formatting**: `make format` (rustfmt with custom config)
- **Line width**: 80 chars for comments (wrapped)
- **Imports**: Grouped by `StdExternalCrate`, granular per crate
- **Naming**: Follow Rust API Guidelines

### Commit Message Format

**PR Title** (becomes commit subject):
```
module [, module2]: what's changed
# or
*: what's changed  # for repo-wide changes
```

**PR Description** must include:
```markdown
Issue Number: close #123

```commit-message
Detailed explanation of changes
```

```release-note
Release note (or "None" if not applicable)
```
```

**Signing**: All commits require DCO sign-off: `git commit -s`

### Pull Request Requirements

1. **Issue linking**: Must reference issue(s) with `close #xxx` or `ref #xxx`
2. **Tests**: Unit test, integration test, or manual test required
3. **Checklist**: Mark performance regressions, breaking changes
4. **Release note**: Required for user-visible changes
5. **CI passes**: `make dev` should pass locally before submission

### Testing Practices

- **Unit tests**: In-source `#[cfg(test)]` modules
- **Integration tests**: `/tests/integrations/`
- **Failpoint tests**: `/tests/failpoints/` (chaos testing)
- **Feature flags**: Use `testexport` feature for test utilities
- **Test engines**: `test-engine-kv-rocksdb`, `test-engine-raft-raft-engine`

## Key Scripts

| Script | Purpose |
|--------|---------|
| `scripts/env` | Run commands in Makefile environment |
| `scripts/test` | Test runner with environment setup |
| `scripts/test-all` | Full test suite runner |
| `scripts/clippy` | Clippy with TiKV configuration |
| `scripts/clippy-all` | Run clippy on all targets |
| `scripts/check-*` | Various validation scripts (license, logs, bins) |

## Feature Flags

**Memory Allocators** (mutually exclusive):
- `jemalloc` (default on Linux with `mem-profiling`)
- `tcmalloc`, `mimalloc`, `snmalloc`, or system allocator

**Build Types:**
- `portable` - Portable RocksDB (default, x86-64 baseline)
- `sse` - SSE4.2 optimizations (default)
- `failpoints` - Enable failpoint injection for testing

**Testing:**
- `testexport` - Export test utilities to other crates
- `test-engine-*` - Specify test storage engines

**Profiling:**
- `pprof-fp` - Frame pointer support for profiling
- `mem-profiling` - Jemalloc memory profiling

## Common Workflows

### First-Time Setup
```bash
git clone https://github.com/tikv/tikv.git && cd tikv
rustup component add rustfmt clippy rust-src
make build  # Verify build works
```

### Daily Development
```bash
cargo check --all  # Fast feedback
# Make changes...
make format && make clippy  # Pre-commit checks
cargo test --all  # Run relevant tests
```

### Pre-PR Checklist
```bash
make dev  # Runs: format + clippy + tests
# Ensure PR title follows format
# Add issue link and release note
git commit -s -m "module: fix issue"
```

### Debugging
```bash
# Build with debug symbols
RUSTFLAGS=-Cdebuginfo=1 make build

# Use tikv-ctl for inspection
./bin/tikv-ctl --help

# Enable failpoints for testing
FAIL_POINT=1 make build
```

## Troubleshooting

**Build fails on Apple Silicon**: Set `ROCKSDB_SYS_PORTABLE=0` and `ROCKSDB_SYS_SSE=0`

**Linker errors**: Ensure cmake, protoc, and C++ compiler are installed

**Test failures**: Some tests are flaky; run specific tests with `./scripts/test $NAME`

**Disk space**: Full builds require 10+ GB; use `cargo clean` periodically

**Memory usage**: Builds can use 8+ GB RAM; reduce parallelism with `CARGO_BUILD_JOBS`

## AI Assistant Notes

- **AGENTS.md** exists with detailed guidance for AI agents
- Project has strict PR requirements (issue links, release notes, checklists)
- Codebase uses workspace with 70+ components - understand module boundaries
- TiKV is production-grade with high code quality standards
- Testing is comprehensive - changes should include appropriate tests
- Documentation is in `/doc/` and on tikv.org (separate repo)

## Resources

- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Documentation**: https://tikv.org/docs/
- **Deep Dive**: https://tikv.org/deep-dive/
- **Rustdoc**: https://tikv.github.io
- **Community**: Slack (tikv-wg), GitHub Discussions
- **Issue Tracker**: https://github.com/tikv/tikv/issues
