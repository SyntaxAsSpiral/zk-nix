#!/usr/bin/env nu
# sort-config.nu — sorts hyprpanel config.json, removing keys for inactive modules

def main [file: string = ""] {
    let target = if $file == "" { $env.CURRENT_FILE | path dirname | path join "config.json" } else { $file }
    let data = open $target

    # 1. Extract active modules from bar.layouts
    let layouts = ($data | get --optional "bar.layouts")
    
    let active_modules = if ($layouts == null) { [] } else {
        $layouts
        | values
        | each {|l|
            let left = ($l | get --optional left | default [])
            let middle = ($l | get --optional middle | default [])
            let right = ($l | get --optional right | default [])
            $left | append $middle | append $right
        }
        | flatten
        | uniq
        | sort
    }

    print $"Active modules kept: ($active_modules | str join ', ')"

    # 2. Define known standard modules (to distinguish from global keys)
    let standard_modules = [
        "battery" "bluetooth" "clock" "cpu" "dashboard" 
        "hypridle" "hyprsunset" "kbLayout" "launcher" 
        "media" "microphone" "netstat" "network" 
        "notifications" "power" "ram" "storage" 
        "submap" "systray" "updates" "volume" 
        "weather" "windowtitle" "workspaces" "worldclock"
    ]

    # 3. Extract any custom modules defined in config
    let custom_modules = ($data | columns | where {|k| $k | str starts-with "bar.customModules."} | each {|k| $k | split row "." | get 2} | uniq)
    
    let all_known_modules = ($standard_modules | append $custom_modules | uniq)

    # 4. Filter and Sort
    
    # Helper to check if a key belongs to a module and if that module is active
    let should_keep = {|key|
        # Check specific deep patterns first (always modules)
        if ($key | str starts-with "bar.customModules.") {
            let parts = ($key | split row ".")
            let mod = ($parts | get 2)
            return ($mod in $active_modules)
        }
        if ($key | str starts-with "theme.bar.buttons.modules.") {
            let parts = ($key | split row ".")
            let mod = ($parts | get 4)
            return ($mod in $active_modules)
        }
        if ($key | str starts-with "theme.bar.menus.menu.") {
            let parts = ($key | split row ".")
            let mod = ($parts | get 4)
            return ($mod in $active_modules)
        }

        # Check shallower patterns (check against known list to avoid false positives)
        # bar.<mod>...
        if ($key | str starts-with "bar.") {
            let parts = ($key | split row ".")
            if ($parts | length) > 1 {
                let mod = ($parts | get 1)
                if ($mod in $all_known_modules) {
                    return ($mod in $active_modules)
                }
            }
        }
        # menus.<mod>...
        if ($key | str starts-with "menus.") {
            let parts = ($key | split row ".")
            if ($parts | length) > 1 {
                let mod = ($parts | get 1)
                if ($mod in $all_known_modules) {
                    return ($mod in $active_modules)
                }
            }
        }
        # theme.bar.buttons.<mod>... (e.g. theme.bar.buttons.battery)
        if ($key | str starts-with "theme.bar.buttons.") {
            let parts = ($key | split row ".")
            if ($parts | length) > 3 {
                let mod = ($parts | get 3)
                # 'modules' is handled above, 'style'/'opacity' etc are not modules
                if ($mod != "modules" and ($mod in $all_known_modules)) {
                    return ($mod in $active_modules)
                }
            }
        }

        # If it doesn't match a module pattern, or matches a pattern but isn't a known module, keep it (Global/Safe)
        return true
    }

    # Helper closure to classify keys for sorting (same as before)
    let get_sort_key = {|key|
        # Check if key belongs to an active module
        let match_list = ($active_modules | where {|m|
            let prefixes = [
                $"bar.($m)."
                $"bar.customModules.($m)."
                $"menus.($m)."
                $"theme.bar.buttons.modules.($m)."
                $"theme.bar.buttons.($m)."
                $"theme.bar.menus.menu.($m)."
            ]
            $prefixes | any {|p| $key | str starts-with $p}
        })
        
        let match = if ($match_list | is-empty) { null } else { $match_list | first }

        if ($match == null) {
            # Global / Other
            if ($key | str starts-with "bar.") {
                [0, "0_bar", $key]
            } else if ($key | str starts-with "theme.") {
                [0, "1_theme", $key]
            } else {
                [0, "2_other", $key]
            }
        } else {
            # Module specific
            [1, $match, $key]
        }
    }

    # Execute: Filter -> Sort -> Save
    let filtered_sorted = $data
        | items { |k, v| {key: $k, value: $v} }
        | where {|row| do $should_keep $row.key }
        | sort-by { |row| do $get_sort_key $row.key }
        | reduce -f {} { |row, acc| $acc | insert $row.key $row.value }

    $filtered_sorted | to json --indent 2 | save -f $target
    print $"Processed ($target)"
}
