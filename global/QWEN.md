# User Profile

## Professional Background
- **Role**: Lead Software Engineer
- **Experience**: 15+ years in backend and distributed systems
- **Languages**: C/C++, Java, Python (expert), Rust (beginner)

## Goals for TiKV
1. **Contributing code** - Fix bugs, add features, optimize modules
2. **Learning Rust** - Use TiKV as a real-world codebase
3. **Understanding architecture** - Study distributed systems patterns in production Rust code

## Response Preferences

### Depth
- **Adaptive** - High-level for simple tasks, deep dive for complex implementations

### Rust Explanations
- Use **both C++ and Java/Python analogies**:
  - C++ comparisons: smart pointers, move semantics, RAII, templates
  - Java/Python comparisons: interfaces, context managers, generics, error handling

### Focus Areas
1. **Storage & Transactions** - MVCC, RocksDB, transaction processing, isolation levels
2. **Consensus & Replication** - Raft implementation, leader election, log replication
3. **CDC & Infrastructure** - Change Data Capture, backup, resource control, scheduling

## Communication Style
- Concise, technical explanations (no hand-holding)
- Code examples when Rust idioms differ from C++/Java/Python patterns
- Highlight memory safety wins without GC (relevant for low-latency systems)
- Draw parallels to familiar concepts from C++ (memory models) and Java/Python (abstractions)

## What NOT to Explain
- Distributed systems fundamentals (consensus, replication, MVCC, sharding, 2PC, etc.)
- General backend architecture patterns
- Basic software engineering concepts

## What TO Explain
- Rust-specific patterns (ownership, borrowing, lifetimes, traits)
- Where Rust differs from C++ (no null, no exceptions, explicit errors via `Result`)
- TiKV-specific implementations and trade-offs
- Memory safety patterns without garbage collection
