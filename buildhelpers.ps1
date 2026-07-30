function Replace($file, $before, $after)
{
    $content = Get-Content $file | Foreach-Object {$_ -replace $before, $after }
    $content | Set-Content $file -Encoding UTF8
}

function UpdateVersion($project, $version)
{
    $file = "./$project/Properties/AssemblyInfo.cs"
    Replace $file "AssemblyVersion\s*\([^\)]+\)"     "AssemblyVersion    (`"$version`")"
    Replace $file "AssemblyFileVersion\s*\([^\)]+\)" "AssemblyFileVersion(`"$version`")"
}

function UpdateVsVersion($project, $version)
{
    UpdateVersion $project $version
        
    Replace "./$project/CodeAlignmentPackage.cs" `
            "\[InstalledProductRegistration\(`"#110`", `"#112`", `"[^`"]+`", IconResourceID = 400\)\]" `
            "[InstalledProductRegistration(`"#110`", `"#112`", `"$version`", IconResourceID = 400)]"
        
    Replace "./$project/source.extension.vsixmanifest" `
            "Id=`"2adcbb11-89c4-451e-97f2-14049154ccad`" Version=`"[^`"]+`"" `
            "Id=`"2adcbb11-89c4-451e-97f2-14049154ccad`" Version=`"$version`""
}

function CollectNpp($is64)
{
    $origin = $pwd

    $outputMod   = if ($is64) { "\x64" }    else { "" }
    $zipSuffix   = if ($is64) { "x64.zip" } else { "x86.zip" }
    $zipFileName = "CodeAlignmentNpp_$($env:APPVEYOR_REPO_TAG_NAME)_$zipSuffix"

    $binDir = "CodeAlignment.Npp\bin$outputMod\$env:CONFIGURATION"
    cd $binDir

    $staging = "staging_release"
    $targetPluginDir = "$staging\CodeAlignmentNpp"
    New-Item -ItemType Directory -Path "$targetPluginDir\CodeAlignment" -Force | Out-Null

    if (Test-Path "CodeAlignmentNpp.dll") {
        Copy-Item "CodeAlignmentNpp.dll" -Destination "$targetPluginDir\" -Force
    }
    if (Test-Path "CodeAlignment\CodeAlignment.Common.dll") {
        Copy-Item "CodeAlignment\CodeAlignment.Common.dll" -Destination "$targetPluginDir\CodeAlignment\" -Force
    }
    if (Test-Path "CodeAlignment\CodeAlignment.Common.WinForms.dll") {
        Copy-Item "CodeAlignment\CodeAlignment.Common.WinForms.dll" -Destination "$targetPluginDir\CodeAlignment\" -Force
    }

    7z a $zipFileName "./$staging/*"

    Push-AppveyorArtifact $zipFileName -FileName $zipFileName

    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue

    cd $origin
}
