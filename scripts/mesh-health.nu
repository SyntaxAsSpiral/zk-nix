#!/usr/bin/env nu
# mesh-health.nu — Structured network diagnostic health report for nxiz
# Collects mesh, local network, and service stats as JSON, pipes to mods for summary

def mesh-hosts [] {
  [
    { host: "zrrh", ip: "100.126.60.24", role: "Local Inference", expect: "online", ssh: true }
    { host: "adeck", ip: "100.89.32.9", role: "Agentic Server", expect: "always-on", ssh: true }
    { host: "zdeck", ip: "100.64.136.57", role: "Gaming", expect: "usually-offline", ssh: false }
    { host: "zk-pixel", ip: "100.96.213.111", role: "Mobile", expect: "intermittent", ssh: false }
    { host: "zk-note", ip: "100.105.239.55", role: "Control Surface", expect: "intermittent", ssh: false }
  ]
}

def collect-remote-info [host: string] {
  try {
    let raw = ^ssh -o ConnectTimeout=3 -o BatchMode=yes $"zk@($host)" "ip -j addr; echo '---SEPARATOR---'; ss -tunp | head -10; echo '---SEPARATOR---'; uptime -s; echo '---SEPARATOR---'; df -h / | tail -1" | str trim
    let parts = $raw | split row "---SEPARATOR---"
    let ifaces = try {
      $parts | get 0 | str trim | from json | where ifname != "lo" | each {|iface|
        { name: $iface.ifname, state: ($iface | get -i operstate | default "?"), addrs: ($iface | get -i addr_info | default [] | each {|a| $"($a.local)/($a.prefixlen)" }) }
      }
    } catch { [] }
    let sockets = $parts | get -i 1 | default "" | str trim
    let uptime_since = $parts | get -i 2 | default "" | str trim
    let disk = $parts | get -i 3 | default "" | str trim
    { interfaces: $ifaces, sockets: $sockets, uptime_since: $uptime_since, disk: $disk }
  } catch { { error: "ssh unreachable" } }
}

def collect-tailscale [] {
  let status = try {
    ^tailscale status --json | from json
  } catch { { error: "tailscale not running" } }

  let peers = if ($status | get -i Peer | is-not-empty) {
    $status | get Peer | transpose id peer | each {|p|
      {
        hostname: ($p.peer | get -i HostName | default "?")
        ip: ($p.peer | get -i TailscaleIPs | default [] | first | default "?")
        os: ($p.peer | get -i OS | default "?")
        online: ($p.peer | get -i Online | default false)
        relay: ($p.peer | get -i Relay | default "")
        rx_bytes: ($p.peer | get -i RxBytes | default 0)
        tx_bytes: ($p.peer | get -i TxBytes | default 0)
      }
    }
  } else { [] }

  {
    self: ($status | get -i Self | get -i HostName | default "nxiz")
    tailnet: ($status | get -i MagicDNSSuffix | default "?")
    peers: $peers
  }
}

def collect-latency [] {
  mesh-hosts | each {|node|
    let ts_ping = try {
      ^tailscale ping -c 1 $node.host | lines | last | str trim
    } catch { "unreachable" }
    let icmp = try {
      ^ping -c 1 -W 2 $node.ip | lines | where $it =~ "time=" | first | default "" | str trim
    } catch { "no reply" }
    let remote = if $node.ssh and ($ts_ping != "unreachable") {
      collect-remote-info $node.host
    } else { null }
    {
      host: $node.host
      ip: $node.ip
      role: $node.role
      expect: $node.expect
      tailscale_ping: $ts_ping
      icmp: $icmp
      remote: $remote
    }
  }
}

def collect-netcheck [] {
  try {
    let raw = do { ^tailscale netcheck } | complete | get stdout | lines
    let udp = $raw | where $it =~ "UDP:" | first | default "" | str trim
    let ipv4 = $raw | where $it =~ "IPv4:" | first | default "" | str trim
    let ipv6 = $raw | where $it =~ "IPv6:" | first | default "" | str trim
    let derp = $raw | where $it =~ "Preferred DERP:" | first | default "" | str trim
    { udp: $udp, ipv4: $ipv4, ipv6: $ipv6, preferred_derp: $derp }
  } catch { { error: "netcheck failed" } }
}

def collect-interfaces [] {
  try {
    ^ip -j addr | from json | where ifname != "lo" | each {|iface|
      {
        name: $iface.ifname
        state: ($iface | get -i operstate | default "?")
        addrs: ($iface | get -i addr_info | default [] | each {|a| $"($a.local)/($a.prefixlen)" })
      }
    }
  } catch { [] }
}

def collect-wifi [] {
  if ("/proc/net/wireless" | path exists) {
    try {
      let raw = open /proc/net/wireless | lines | skip 2 | first | split row -r '\s+' | compact --empty
      { interface: ($raw | get -i 0 | default "?"), link: ($raw | get -i 2 | default "?"), level: ($raw | get -i 3 | default "?"), noise: ($raw | get -i 4 | default "?") }
    } catch { { status: "parse error" } }
  } else {
    { status: "no wireless" }
  }
}

def collect-connections [] {
  try {
    ^nmcli -t -f NAME,TYPE,DEVICE connection show --active
      | lines | each {|l| let parts = ($l | split row ":"); { name: ($parts | get -i 0 | default ""), type: ($parts | get -i 1 | default ""), device: ($parts | get -i 2 | default "") } }
  } catch { [] }
}

def collect-dns [] {
  try {
    ^dig +short lexemancy.com | lines | compact --empty | take 3
  } catch { ["dig unavailable"] }
}

def collect-inference-zrrh [] {
  try {
    let resp = http get --max-time 3sec http://zrrh:1234/v1/models
    $resp | get -i data | default [] | each {|m| $m.id }
  } catch { { status: "OFFLINE" } }
}

def collect-sockets [] {
  try {
    ^ss -tunp | lines | skip 1 | take 15 | each {|l|
      let parts = ($l | split row -r '\s+' | compact --empty)
      {
        proto: ($parts | get -i 0 | default "")
        state: ($parts | get -i 1 | default "")
        local: ($parts | get -i 4 | default "")
        peer: ($parts | get -i 5 | default "")
      }
    }
  } catch { [] }
}

# === Main ===

def main [
  --raw (-r)  # Emit raw JSON without piping to mods
  --api (-a): string = "zrrh"  # mods API to use
  --model (-m): string = "gpt-oss-20b-heretic"  # mods model to use
] {
  print "🔍 Collecting mesh health data..."

  let report = {
    host: "nxiz"
    timestamp: (date now | format date "%Y-%m-%dT%H:%M:%S%z")
    tailscale: (collect-tailscale)
    latency: (collect-latency)
    netcheck: (collect-netcheck)
    interfaces: (collect-interfaces)
    wifi: (collect-wifi)
    active_connections: (collect-connections)
    dns: (collect-dns)
    inference_zrrh: (collect-inference-zrrh)
    sockets: (collect-sockets)
  }

  if $raw {
    $report | to json
  } else {
    let json_report = ($report | to json)
    print $json_report
    print "\n🤖 Generating health summary...\n"
    $json_report | ^mods --api $api --model $model "You are a network diagnostics analyst for a Tailscale mesh (nxiz/zrrh/adeck). Each host has an 'expect' field: 'always-on' means downtime is alarming, 'usually-offline' means offline is normal (e.g. zdeck is a gaming PC), 'intermittent' means mobile devices that come and go. Analyze this JSON health report. Give a concise status summary: what's up, what's down, any latency concerns, service availability. Flag only unexpected states. Be terse and technical."
  }

  input "\npress enter to close"
}
