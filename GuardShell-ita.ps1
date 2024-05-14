$pzw = Read-Host "`nScegliere la password (premere Invio per usare un passfile)"
$nolist = Read-Host "`nScegliere i processi da proteggere, separati dalla virgola (x, y, etc.)"
$script = Read-Host "`nScegliere il percorso e il nome (.ps1) per lo script di protezione"
if ("$(("$script").split(".")[1])" -ne "ps1") {
    Write-Host "Il file dello script deve avere estensione .ps1; ricordarsi di aggiungerla prima di usarlo" -ForegroundColor Cyan
}
$sec = Get-FileHash -Algorithm SHA512 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes(($("$(Get-FileHash -Algorithm SHA384  -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("$($pzw+"$($(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"$($(whoami).split('\')[0])").substring(4)+$("$(Get-FileHash -Algorithm SHA384  -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("$($pzw+"$($(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"$($(whoami).split('\')[0])").Substring(0,4))[-1..-("$("$(Get-FileHash -Algorithm SHA384  -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("$($pzw+"$($(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"$($(whoami).split('\')[0])").substring[4]+$("$(Get-FileHash -Algorithm SHA384  -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("$($pzw+"$($(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"$($(whoami).split('\')[0])").Substring(0,4)").Length] -join ''))) | ForEach-Object Hash
$passfile = Read-Host "`nScegliere il passfile (facoltativo, tranne se non è stata scelta una password)"
if (($passfile -ne "") -and (Test-Path "$passfile")) {
    $Hpassfile = Get-FileHash "$passfile" -Algorithm SHA1
    $psfileH = $Hpassfile.Hash
    $passfolder = Read-Host "`nScegliere la passfolder in cui il passfile sbloccherà la protezione"
    if (($passfolder -ne "") -and (Test-Path "$passfolder")) {
        $SFolder = Read-Host "`nScegliere la cartella da proteggere (facoltativa, tranne se è stata impostata una password)"
        if (($SFolder -ne "") -and ((Test-Path "$SFolder") -eq $false)) {
            Write-Host "`nPercorso della cartella da proteggere non valido; lo script terminerà" -ForegroundColor Yellow
            cmd /C pause
            exit
        }
        elseif (($SFolder -eq "") -and (($pzw -ne ""))) {
            Write-Host "`nIl passfile non protegge alcuna cartella" -ForegroundColor Cyan
        }
    } else {
        Write-Host "`nPercorso della passfolder non valido; riprovare" -ForegroundColor Yellow
        cmd /C pause
        exit
    }
}
elseif (($passfile -ne "") -and ((Test-Path "$passfile") -eq $false)) {
    Write-Host "`nPercorso del passfile non valido; riprovare" -ForegroundColor Yellow
    cmd /C pause
    exit
}
# Check for minimum required infos
if (("$pzw" -eq "") -and ("$passfile" -eq "")) {
    Write-Host "`nErrore di configurazione, serve almeno una password o un passfile; lo script terminerà" -ForegroundColor Yellow
    cmd /C pause
    exit
}
if ((Test-Path "$("$script" | Split-Path -parent)") -eq $false) {
    Write-Host "`nErrore di configurazione, il percorso dello script di protezione non è valido; lo script terminerà" -ForegroundColor Yellow
    cmd /C pause
    exit
}

# Create the protection script
New-Item -ItemType File -Path $script -Value @"
using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms

`# Set the blocklist
`$blocklist = "$nolist" -split "," | ForEach-Object { `$_.Trim() }

`# Create safelist file
if ((Test-Path "`$("$script" | Split-Path -parent)\safe.txt") -eq `$false) {
    `$safelist = "`$("$script" | Split-Path -parent)\safe.txt"
    New-Item -ItemType File -Path `$safelist
} else {
    `$safelist = "`$("$script" | Split-Path -parent)\safe.txt"
}

while (`$true) {
    `# If proper settings have been given, block the protected folder in Explorer if the passfile is not in the passfolder
    If (("$passfolder" -ne "") -and ("$passfile" -ne "")) {
        foreach (`$folder in (New-Object -ComObject Shell.Application).Windows()) {
            if ((`$folder.LocationURL -eq ([Uri]"$Sfolder").AbsoluteUri) -and ((Get-ChildItem "$($passfolder)" | Get-FileHash -Algorithm SHA1 | Where-Object {`$_.hash -eq "$psfileH"}) -eq `$null)) {
            `$folder.Quit()
            `Start-Sleep 1
            }
        }
    }
    `# Check if safelist has been deleted and in case re-create it
    if ((Test-Path "`$("$script" | Split-Path -parent)\safe.txt") -eq `$false) {
        `$safelist = "`$("$script" | Split-Path -parent)\safe.txt"
        New-Item -ItemType File -Path `$safelist
    }
    `# Clean the safelist from inactive previously authorized processes
    if (`$safelist -ne "") {
        foreach (`$safeproc in (Get-Content "`$safelist")) {
                If ((Get-Process | Select-Object Name | Select-String `$safeproc -SimpleMatch) -eq `$null) {
                    Set-Content ((Get-Content "`$safelist") | ForEach-Object { `$_ -replace `$safeproc, `$null } | Where-Object { `$_.trim() -ne "" }) -Path "`$safelist"
                }
        }
    }
    `# Start the process monitoring
    foreach (`$proc in Get-Process) {
        if ((`$proc.Name -in `$blocklist) -and (`$proc.Name -notin (Get-Content "`$safelist"))) {
                `$proc.kill() `# "Close" will not work with system processes like taskmgr or mmc
                `# Check if passfile is set intead of password 
                if (("$pzw" -eq "") -and ("$passfile" -ne "")) {
                    if (((Get-ChildItem "$($passfolder)" | Get-FileHash -Algorithm SHA1 | Where-Object {`$_.hash -eq "$psfileH"}) -ne `$null)) {
                        `$proc.Name | Out-File "`$safelist" -Encoding ASCII -Append
                        Start-Process `$proc.Name
                        Start-Sleep 5
                        break
                    } else {
                        break
                    } # if a password have been set, procede to ask for it with Windows Forms
                } else {
                    `# Hide the shell
                    Add-Type -Name ConsoleUtils -Namespace Win32 -MemberDefinition '
                        [DllImport("kernel32.dll")]
                        public static extern IntPtr GetConsoleWindow();
                    
                        [DllImport("user32.dll")]
                        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
                    
                        public const int SW_HIDE = 0;
                    '
                    `$consoleWindow = [Win32.ConsoleUtils]::GetConsoleWindow()
                    [Win32.ConsoleUtils]::ShowWindow(`$consoleWindow, [Win32.ConsoleUtils]::SW_HIDE)
                    `# Crate main form
                    [System.Windows.Forms.Form]`$Window = @{
                        Visible = `$false
                        Opacity = 0.95
                        Text = `$proc.Name
                        Size = New-Object System.Drawing.Size(215,150)
                        BackColor = "#0b335b"
                        StartPosition = 'CenterScreen'
                        FormBorderStyle = "FixedSingle"
                        MaximizeBox = `$false
                        MinimizeBox = `$false
                        TopMost = `$true
                        ShowInTaskbar = `$false
                    }
                    `# Create the label
                    [System.Windows.Forms.Label]`$Label = @{
                        Text = "Enter password:"
                        Font = "Verdana, 10"
                        ForeColor = "#ffffff"
                        Location = New-Object System.Drawing.Point(10,15)
                        Size = New-Object System.Drawing.Size(200,20)
                    }
                    `$Window.Controls.Add(`$Label)
                    `# Create the textbox
                    [System.Windows.Forms.TextBox]`$textBox = @{
                        Location = New-Object System.Drawing.Point(10,40)
                        Size = New-Object System.Drawing.Size(175,20)
                        Font = "Verdana, 11"
                        BackColor = "#08243f"
                        ForeColor = "#ffffff"
                        MaxLength = 16
                        PasswordChar = '*'
                    }
                    `$Window.Controls.Add(`$textBox)
                    `# Create the button
                    [System.Windows.Forms.Button]`$Button = @{
                        Location = New-Object System.Drawing.Point(65,80)
                        Size = New-Object System.Drawing.Size(70,25)
                        Text = "OK"
                        BackColor = "#5e5f64"
                        ForeColor = "#ffffff"
                    }
                    `$Window.Controls.Add(`$Button)
                    `# Set the button action
                    `$Button.Add_Click({
                        `$textBox.Text
                        `$Window.Visible = `$false
                    })
                    `# Create a timer
                    `$timer = [Timer]::new()
                    `$timer.Interval = 5000 # milliseconds
                    `# Set up the event handler for the timer
                    `$timer.Add_Tick({
                        # Close the window
                        `$Window.Close()
                    })
                    `# Start the timer (have to be started before the form display)
                    `$timer.Start()
                    `# Display the form
                    `$Window.ShowDialog() | Out-Null
                    `# Dispose (stop) the timer, even when the form is closed by the user
                    `$timer.Dispose() 
                    `# release all resources held by any managed objects
                    `$Window.Dispose()
                    
                    `# get the textbox password
                    `$check = `$textBox.Text
                    `# if password is left empty, the process is stopped
                    if (`$check -eq "") {
                        break
                    }
                    `# check the password and if it's right, start the process
                    elseif ("$sec" -eq ((Get-FileHash -Algorithm SHA512 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes((`$("`$(Get-FileHash -Algorithm SHA384 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("`$(`$check+"`$(`$(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"`$(`$(whoami).split('\')[0])").substring(4)+`$("`$(Get-FileHash -Algorithm SHA384 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("`$(`$check+"`$(`$(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"`$(`$(whoami).split('\')[0])").Substring(0,4))[-1..-("`$("`$(Get-FileHash -Algorithm SHA384 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("`$(`$check+"`$(`$(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"`$(`$(whoami).split('\')[0])").substring[4]+`$("`$(Get-FileHash -Algorithm SHA384 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes("`$(`$check+"`$(`$(whoami).split('\')[1])")"))) | ForEach-Object Hash)"+"!"+"`$(`$(whoami).split('\')[0])").Substring(0,4)").Length] -join ''))) | ForEach-Object Hash))) {
                        `$proc.Name | Out-File "`$safelist" -Encoding ASCII -Append
                        Start-Process `$proc.Name
                    }
                }
        }
    }
}
"@
# Hide the protection script
attrib $script +h +s