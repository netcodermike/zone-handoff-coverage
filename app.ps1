param([Parameter(Mandatory=$true, Position=0)][string] $InputPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Invoke-Analysis($data) {
    $until = $data.until
    if ($until -isnot [long] -or $until -lt 1 -or $data.zones -isnot [array] -or $data.assignments -isnot [array]) {
        throw 'Provide a positive window end, zones, and assignments'
    }
    $events = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($zone in $data.zones) {
        if ($zone -isnot [string] -or [string]::IsNullOrWhiteSpace($zone) -or $events.ContainsKey($zone)) { throw 'Provide unique nonempty zone names' }
        $deltas = [System.Collections.Generic.SortedDictionary[long,int]]::new()
        $deltas[[long]0] = 0
        $deltas[$until] = 0
        $events.Add($zone, $deltas)
    }
    foreach ($assignment in $data.assignments) {
        if ($assignment -isnot [array] -or $assignment.Count -ne 3) { throw 'Each assignment needs a zone, start, and end' }
        $zone, $start, $end = $assignment
        if ($zone -isnot [string] -or !$events.ContainsKey($zone) -or $start -isnot [long] -or $end -isnot [long] -or $start -lt 0 -or $end -gt $until -or $end -le $start) { throw 'Invalid zone or interval' }
        $deltas = $events[$zone]
        if (!$deltas.ContainsKey($start)) { $deltas[$start] = 0 }
        if (!$deltas.ContainsKey($end)) { $deltas[$end] = 0 }
        $deltas[$start]++
        $deltas[$end]--
    }
    $zones = @(foreach ($zone in $data.zones) {
        $groups = @{ gaps = [System.Collections.Generic.List[object]]::new(); overlaps = [System.Collections.Generic.List[object]]::new() }
        $previous = 0
        $cover = 0
        foreach ($event in $events[$zone].GetEnumerator()) {
            if ($event.Key -gt $previous -and $cover -ne 1) {
                $segments = if ($cover -eq 0) { ,$groups.gaps } else { ,$groups.overlaps }
                if ($segments.Count -gt 0 -and $segments[$segments.Count-1][1] -eq $previous) {
                    $segments[$segments.Count-1][1] = $event.Key
                } else { $segments.Add(@($previous, $event.Key)) }
            }
            $cover += $event.Value
            $previous = $event.Key
        }
        @{zone = $zone; gaps = $groups.gaps.ToArray(); overlaps = $groups.overlaps.ToArray()}
    })
    @{ zones = $zones }
}

try {
    $payload = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -AsHashtable
    if ($payload -isnot [System.Collections.IDictionary]) { throw 'Input must be a JSON object' }
    Invoke-Analysis $payload | ConvertTo-Json -Depth 30 -Compress
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
