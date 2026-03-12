pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values).sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property string cachePath: "/home/zk/.local/share/qs-launcher/history"
    property var launchCounts: ({})

    Component.onCompleted: loadCache()

    function loadCache() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + cachePath, false);
        xhr.send();
        var counts = {};
        if (xhr.responseText) {
            xhr.responseText.trim().split("\n").forEach(line => {
                var name = line.trim().toLowerCase();
                if (name) counts[name] = (counts[name] || 0) + 1;
            });
        }
        launchCounts = counts;
    }

    function fuzzyQuery(search: string): var {
        var results = Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);

        if (search === "") {
            results.sort((a, b) => {
                var ca = launchCounts[a.name.toLowerCase()] || 0;
                var cb = launchCounts[b.name.toLowerCase()] || 0;
                return cb - ca || a.name.localeCompare(b.name);
            });
        }

        return results;
    }

    function getIcon(iconName) {
        if (!iconName || iconName.length === 0) return false;
        return Quickshell.iconPath(iconName, true);
    }

    function logLaunch(appName: string) {
        var key = appName.toLowerCase();
        var counts = launchCounts;
        counts[key] = (counts[key] || 0) + 1;
        launchCounts = counts;
        writeProc.command = ["sh", "-c", "mkdir -p $(dirname " + shellEscape(cachePath) + ") && printf '%s\\n' " + shellEscape(appName) + " >> " + shellEscape(cachePath)];
        writeProc.running = true;
    }

    function shellEscape(s: string): string {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    Process {
        id: writeProc
        onRunningChanged: if (!running) command = []
    }
}
