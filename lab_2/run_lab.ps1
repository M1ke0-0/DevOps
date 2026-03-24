$ErrorActionPreference = "Continue"

$ReportPath = "e:\Devops_lab\lab_2\lab2_output.txt"
Set-Content $ReportPath ""

function Run-Cmd {
    param([string]$cmd)
    $out = "PS e:\Devops_lab\lab_2> $cmd`n"
    $out | Add-Content $ReportPath
    Write-Host "> $cmd"
    $res = Invoke-Expression $cmd 2>&1 | Out-String
    if ($res) {
        $res | Add-Content $ReportPath
        Write-Host $res
    }
}

cd e:\Devops_lab\lab_2

# Configure Git globally to avoid user missing config config issues
Run-Cmd "git config --global user.name `"Student`""
Run-Cmd "git config --global user.email `"student@example.com`""
Run-Cmd "git config --global init.defaultBranch master"

# 4.2.1
Run-Cmd "mkdir repo_new -Force | Out-Null"
cd repo_new
Run-Cmd "git init"
Run-Cmd "git status"

# 4.2.2
Set-Content "file.txt" ""
Run-Cmd "git status"
Run-Cmd "git add ."
Run-Cmd "git status"

Run-Cmd "mkdir empty -Force | Out-Null"
cd empty
Set-Content ".gitkeep" ""
cd ..

Run-Cmd "git status"
Run-Cmd "git add ."
Run-Cmd "git commit -m `"First commit`""
Run-Cmd "git status"

# 4.2.3
cd ..
Run-Cmd "mkdir repo_master -Force | Out-Null"
cd repo_master
Run-Cmd "git init"

cd ../repo_new
Run-Cmd "git remote add origin `"../repo_master`""
Run-Cmd "git push --set-upstream origin master"

cd ..
Run-Cmd "Remove-Item -Recurse -Force repo_master"
Run-Cmd "mkdir repo_master -Force | Out-Null"
cd repo_master
Run-Cmd "git init --bare"

cd ../repo_new
Run-Cmd "git push --set-upstream origin master"
Run-Cmd "git push"
Run-Cmd "git status"

# 4.2.4
cd ..
Run-Cmd "mkdir repo_test -Force | Out-Null"
cd repo_test
Run-Cmd "git init"
Set-Content "rand.txt" ""
Run-Cmd "git add ."
Run-Cmd "git commit -m `"aaa`""
Run-Cmd "git remote add origin `"../repo_master`""
Run-Cmd "git push --set-upstream origin master"

cd ..
Run-Cmd "Remove-Item -Recurse -Force repo_test"

# 4.2.5
Run-Cmd "git clone `"./repo_master`" `"repo_cloned`""
cd repo_cloned
Run-Cmd "git status"

# 4.2.6
Set-Content "file.txt" "Text from repo_cloned repository"
Run-Cmd "git status"
Run-Cmd "git add ."
Run-Cmd "git commit -m `"second`""
Run-Cmd "git push"

cd ../repo_new
Set-Content "file.txt" "Text from repo_new repository"
Run-Cmd "git add ."
Run-Cmd "git commit -m `"other second`""
Run-Cmd "git push"

$env:GIT_MERGE_AUTOEDIT = "no"
Run-Cmd "git pull"

$resolved = @"
<<<<<<< HEAD
Text from repo_new repository
=======
Text from repo_cloned repository
>>>>>>> 
"@
# But we should resolve it instead of writing the conflict markers
$resolved = "Text from repo_new repository`r`nText from repo_cloned repository"
Set-Content "file.txt" $resolved

Run-Cmd "git status"
Run-Cmd "git add file.txt"
Run-Cmd "git commit -m `"Merged`""
Run-Cmd "git status"
Run-Cmd "git push"
Run-Cmd "git log -n 4"
