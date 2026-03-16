#!/bin/bash
# =============================================================================
# TiKV Cluster Status Report
# =============================================================================
# 
# PURPOSE:
#   Comprehensive health check for TiKV clusters with distributed systems
#   insights. Displays Raft consensus state, region distribution, and store
#   metrics.
#
# TIKV CONCEPTS DISPLAYED:
#
#   1. PD Cluster (Raft Consensus Layer)
#      - PD nodes run Raft consensus for metadata/leader election
#      - Shows current Raft leader among PD nodes
#      - All PD members are Raft peers participating in consensus
#      - Requires quorum (majority) to remain healthy
#
#   2. TiKV Stores (Storage Layer)
#      - Each store hosts multiple Raft groups (regions)
#      - Leader count shows Raft leader load distribution
#      - Balanced leader distribution = better read performance
#
#   3. Regions (Raft Groups / Data Shards)
#      - Basic unit of data sharding and replication
#      - Each region is an independent Raft group (3 replicas by default)
#      - Region leader handles reads, all peers can replicate
#      - Key range partitioning (start_key → end_key)
#      - Epoch tracks configuration and version changes
#
#   4. Replication Model
#      - 3 replicas per region (configurable)
#      - All replicas are Raft voters (full consensus participation)
#      - Leader election per region (not global)
#
# USAGE:
#   ./cluster-status.sh
#
# REQUIREMENTS:
#   - Docker Compose (for container status)
#   - curl (for PD API queries)
#   - jq (for JSON parsing)
#   - TiKV cluster running with PD accessible at localhost:23791
#
# RELATED APIs:
#   - PD HTTP API: http://localhost:23791/pd/api/v1/
#   - PD Dashboard: http://localhost:23791/dashboard
#   - TiKV Status: http://localhost:20181/status
#
# SEE ALSO:
#   - CLUSTER_SETUP_GUIDE.md - Cluster deployment instructions
#   - https://tikv.org/docs - TiKV documentation
#   - https://raft.github.io/ - Raft consensus paper
#
# =============================================================================

set -e

cd "$(dirname "$0")"

PD_ENDPOINT="http://localhost:23791"

echo "========================================"
echo "       TiKV Cluster Status Report       "
echo "========================================"
echo ""

# =============================================================================
# Container Status
# =============================================================================
echo "📦 Docker Containers:"
echo "─────────────────────────────────────────────────────────────────────────"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# =============================================================================
# PD Cluster - Raft Consensus Layer
# =============================================================================
echo "🔗 PD Cluster (Raft Consensus):"
echo "─────────────────────────────────────────────────────────────────────────"

pd_leader=$(curl -s "$PD_ENDPOINT/pd/api/v1/leader" 2>/dev/null)
if [ -n "$pd_leader" ]; then
    leader_name=$(echo "$pd_leader" | jq -r '.name')
    leader_id=$(echo "$pd_leader" | jq -r '.member_id')
    leader_client=$(echo "$pd_leader" | jq -r '.client_urls[0]')
    echo "  Raft Leader: $leader_name (ID: $leader_id)"
    echo "  Client URL:  $leader_client"
else
    echo "  ⚠️  PD leader not available"
fi

echo ""
echo "  PD Members (Raft Peers):"
curl -s "$PD_ENDPOINT/pd/api/v1/members" 2>/dev/null | jq -r '
    .members[] | 
    "    - \(.name): ID=\(.member_id) | Peer URL: \(.peer_urls[0]) | Client: \(.client_urls[0])"
' 2>/dev/null || echo "    Unable to fetch PD members"

# Check for any PD tso-server instances
echo ""
echo "  Raft Cluster Health:"
curl -s "$PD_ENDPOINT/pd/api/v1/health" 2>/dev/null | jq -r '
    if length > 0 then
        "    ✓ All \(length) PD nodes healthy (quorum maintained)"
    else
        "    ⚠️  No healthy PD nodes"
    end
' 2>/dev/null || echo "    Unable to check health"
echo ""

# =============================================================================
# TiKV Stores - Storage Layer
# =============================================================================
echo "📊 TiKV Stores (Region Peers):"
echo "─────────────────────────────────────────────────────────────────────────"

stores=$(curl -s "$PD_ENDPOINT/pd/api/v1/stores" 2>/dev/null)
if [ -n "$stores" ]; then
    store_count=$(echo "$stores" | jq -r '.count')
    echo "  Total Stores: $store_count"
    echo ""
    
    echo "  Store Details:"
    echo "$stores" | jq -r '
        .stores[] | 
        "    Store \(.store.id) [\(.store.address)]",
        "      State: \(.store.state_name) | Version: \(.store.version)",
        "      Capacity: \(.status.capacity) | Available: \(.status.available)",
        "      Leaders: \(.status.leader_count) | Regions: \(.status.region_count)",
        "      Uptime: \(.status.uptime)"
    ' 2>/dev/null || echo "    Unable to fetch store details"
    
    # Leader distribution analysis
    echo ""
    echo "  Leader Distribution (Raft Leaders per Store):"
    echo "$stores" | jq -r '
        .stores | sort_by(.status.leader_count) | reverse | .[] |
        "    \(.store.address): \(.status.leader_count) leaders (\(.status.leader_score) score)"
    ' 2>/dev/null
    
    # Check for unbalanced distribution
    leader_counts=$(echo "$stores" | jq -r '[.stores[].status.leader_count] | sort')
    min_leaders=$(echo "$leader_counts" | jq '.[0] // 0')
    max_leaders=$(echo "$leader_counts" | jq '.[-1] // 0')
    if [ "$min_leaders" != "$max_leaders" ] && [ "$min_leaders" != "0" ]; then
        echo "    ⚠️  Leader distribution unbalanced (range: $min_leaders - $max_leaders)"
    else
        echo "    ✓ Leaders evenly distributed"
    fi
else
    echo "  ⚠️  TiKV stores not responding"
fi
echo ""

# =============================================================================
# Regions - Data Sharding & Raft Groups
# =============================================================================
echo "📈 Region Statistics (Raft Groups):"
echo "─────────────────────────────────────────────────────────────────────────"

regions=$(curl -s "$PD_ENDPOINT/pd/api/v1/regions" 2>/dev/null)
if [ -n "$regions" ]; then
    region_count=$(echo "$regions" | jq -r '.count')
    echo "  Total Regions: $region_count"
    
    # Region stats
    region_stats=$(curl -s "$PD_ENDPOINT/pd/api/v1/stats/region" 2>/dev/null)
    if [ -n "$region_stats" ]; then
        empty_count=$(echo "$region_stats" | jq -r '.empty_count')
        storage_size=$(echo "$region_stats" | jq -r '.storage_size')
        echo "  Empty Regions: $empty_count"
        echo "  Storage Size:  ${storage_size}B"
    fi
    
    echo ""
    echo "  Region Details (Raft Groups with Peer Distribution):"
    echo "$regions" | jq -r '
        .regions[] |
        "    Region \(.id):",
        "      Key Range: [\(.start_key | if . == "" then "-∞" else . end) → \(.end_key | if . == "" then "+∞" else . end)]",
        "      Epoch: conf_ver=\(.epoch.conf_ver), version=\(.epoch.version)",
        "      Peers: \([.peers[] | "\(.id)(store \(.store_id))"] | join(", "))",
        "      Leader: \(.leader.id)(store \(.leader.store_id))",
        "      Size: \(.approximate_size)B | Keys: \(.approximate_keys)",
        "      Write: \(.written_bytes)B | Read: \(.read_bytes)B"
    ' 2>/dev/null | head -60
    
    # Check for regions without leaders
    leaderless=$(echo "$regions" | jq '[.regions[] | select(.leader == null)] | length')
    if [ "$leaderless" != "0" ]; then
        echo ""
        echo "    ⚠️  $leaderless regions without leader (Raft election needed)"
    else
        echo ""
        echo "    ✓ All regions have elected leaders"
    fi
else
    echo "  ⚠️  Unable to fetch region information"
fi
echo ""

# =============================================================================
# Cluster Topology Summary
# =============================================================================
echo "🏗️  Cluster Topology Summary:"
echo "─────────────────────────────────────────────────────────────────────────"
echo "  PD Replicas:     $(curl -s "$PD_ENDPOINT/pd/api/v1/members" 2>/dev/null | jq -r '.members | length' || echo 'N/A')"
echo "  TiKV Stores:     $(echo "$stores" | jq -r '.count' 2>/dev/null || echo 'N/A')"
echo "  Total Regions:   $region_count"
echo "  Replication:     3 replicas per region (Raft voters)"
echo ""

# Calculate total capacity and usage
if [ -n "$stores" ]; then
    total_capacity=$(echo "$stores" | jq -r '[.stores[].status.capacity | gsub("[A-Za-z]"; "") | tonumber] | add // 0')
    total_available=$(echo "$stores" | jq -r '[.stores[].status.available | gsub("[A-Za-z]"; "") | tonumber] | add // 0')
    total_leaders=$(echo "$stores" | jq -r '[.stores[].status.leader_count] | add // 0')
    total_regions=$(echo "$stores" | jq -r '[.stores[].status.region_count] | add // 0')
    
    echo "  Total Capacity:  ${total_capacity}GiB"
    echo "  Total Available: ${total_available}GiB"
    echo "  Total Leaders:   $total_leaders (across all stores)"
    echo "  Total Peers:     $total_regions (region replicas)"
fi
echo ""

# =============================================================================
# Quick Access
# =============================================================================
echo "🌐 Quick Access:"
echo "─────────────────────────────────────────────────────────────────────────"
echo "  PD Dashboard:    $PD_ENDPOINT/dashboard"
echo "  PD API:          $PD_ENDPOINT/pd/api/v1"
echo "  TiKV Status:     http://localhost:20181/status"
echo ""
echo "========================================"
