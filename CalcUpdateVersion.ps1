# PowerShell-Skript zur Berechnung einer semantischen Version basierend auf Git-Commit-Nachrichten und aktualisierung der .csproj-Datei

function Get-SemanticVersion {
    param (
        [string[]] $commitMessages
    )

    $major = 0
    $minor = 0
    $patch = 0

    [array]::Reverse($commitMessages)
    foreach ($message in $commitMessages) {
        if ($message -match "^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([\w\s-]*\))?(!:|:.*\n\n((.+\n)+\n)?BREAKING CHANGE:\s.+)") {
            $major++
            $minor = 0
            $patch = 0
        }
        elseif ($message -match "^(feat)(\([\w\s-]*\))?:") {
            $minor++
            $patch = 0
        }
        elseif ($message -match "^(build|chore|ci|docs|fix|perf|refactor|revert|style|test)(\([\w\s-]*\))?:") {
            $patch++
        }
    }

    return "$major.$minor.$patch"
}

function Update-CsprojVersion {
    param (
        [string] $csprojFilePath,
        [string] $newVersion
    )

    [xml]$xml = Get-Content -Path $csprojFilePath

    $versionElement = $xml.SelectSingleNode("//Project/PropertyGroup/Version")
    if ($versionElement) {
        $versionElement.'#text' = $newVersion
    } 
    else {
        $propertyGroup = $xml.CreateElement("PropertyGroup")
        $xml.Project.AppendChild($propertyGroup)
        $versionElement = $xml.CreateElement("Version")
        $versionElement.InnerText = $newVersion
        $propertyGroup.AppendChild($versionElement)
    }

    $xml.Save($csprojFilePath)
}

$commitMessages = git log --pretty=format:"%s" | Select-String -Pattern "^(.*)"

if ($commitMessages.Count -gt 0) {
    $semanticVersion = Get-SemanticVersion -commitMessages $commitMessages
    Write-Output "Die berechnete semantische Version ist: $semanticVersion"

    $csprojFilePath = Get-Item *.csproj
    Update-CsprojVersion -csprojFilePath $csprojFilePath -newVersion $semanticVersion
    Write-Output "Die Version in der .csproj-Datei wurde erfolgreich aktualisiert."
} 
else {
    Write-Output "Es wurden keine Git-Commits im aktuellen Verzeichnis gefunden."
}
