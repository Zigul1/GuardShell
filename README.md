# GuardShell
(![309580213-98e4d648-c4c9-440f-84d4-3c6513dcd349](https://github.com/Zigul1/GuardShell/assets/157254375/97a8a953-3e88-4cef-b120-b0e6c4aab129) la versione in italiano è "*GuardShell-ita.ps1*", come guida c'è [questo articolo](https://turbolab.it/sicurezza-13/guardshell-proteggere-programmi-password-passfile-4129) )

GuardShell is a PowerShell script for **Windows 10** that guides the user to quickly generate another PowerShell script (the "protection script", you will chose its name), that allows to **protect processes and programs** (somehow also folders, more on that later) with a **password** or with a **passfile** (that is not just a file instead of a password, more on that later too). It can be used to password-protect browsers or applications, but **it must not be used on system crucial processes**, otherwise the OS will get unstable or compromised.

If you want to know the exact name of the main process of a program, you can use the following PowerShell command `Get-Process | Where-Object {$_.MainWindowTitle -match "..."}` using a meaningful word from the title of the program main window; for example:
![mbam-ex](https://github.com/Zigul1/GuardShell/assets/157254375/43c66e54-6cd1-43b8-a6fa-f78cfa8fe7c7)
 
Once you have known the **exact process name** of the program you want to protect, you can launch GuardShell; the required infos are those shown in this example:
![example](https://github.com/Zigul1/GuardShell/assets/157254375/ffbe8153-4c58-4c45-b3b3-859ee05133eb)

Not all the fields have to be compiled, you can choose to use only a password or only a passfile, or a password for the processes and a passfile for some folder (may it be the one containig the script or another one). In case you opt for the password, consider that you will have around **5 second** to write it, but you can always copy and paste it if it's too long (just manage the clipboard history consequently). This is the small window that will pop up (you may need to click on it before typing) and will read your password even if you don't press "OK":

![password](https://github.com/Zigul1/GuardShell/assets/157254375/d313f7ca-40a6-44b7-bdae-f958056b14b3)

In case you choose only (or also) the **passfile**, this is how it works: ***if the chosen passfile is in the chosen passfolder, the protection is off; if the passfile is not in the passfolder, the protection is on***; just like a key and a lock. So the basic idea is to keep the passfile *not* in the passfolder (in an external device? in the cloud? compressed elsewhere?) and, when it's needed, just make a *copy* of it in the passfolder. The passfile is valid as long as its SHA1 hash doesn't change; you can rename it, just don't alter its data. Consider that when the passfile protection is on, there will be no warnings nor requests and it will be up to the user to eventually restore the protection.

When the "protection script" (as filter.ps1 in the example) has been created, it's possibile to set it as a **scheduled task** to run at startup or when a user logs in, when a certain events occurs, etc.


## FAQ

+ **How to be sure to have properly configured the "protection script"?**

Before creating the "protection script", GuardShell will check if the designated folders exist and if there is any information missing. Just be sure to remember the password and the passfile, they are stored **hardcoded but hased** in the script (it is not necessary, but the password is salted and manipulated). The blocklist with the monitored processes and the passfolder are in **plain text** in the script, so you can retrieve them.

+ **Why, after the protection has been removed (by password or passfile), the program is launched but the file is not opened?**

Must be remembered that unlocking a process, with a password or with a passfile, will not open directly the file that made tha call. For example, if you try to open "notes.txt" and Notepad is a checked process, when you unlock the protection, Notepad will **open empty**: you will have to open "notes.txt" from Notepad GUI, or simply clicking again on the file (without closing Notepad, if using the password protection: at least one instance of Notepad have to be kept open, to avoid a sudden **protection fallback**). Further examples: this will not happen with Task Manager, but will happen with Task Scheduler.

+ **Reinstalling a program controlled by the script, will evade its monitoring?**

The "protection script" monitors the processes looking for **blacklisted processes names**, is not relevant if the blacklisted programs get reinstalled or are not even installed; as soon as a process named in the blocklist is detected by the script (without being already put in the safelist) the protection will trigger.

+ **What happens in the protection script folder during the monitoring?**

In the "protection script" folder, that can be any folder, the script will be hidden and you will find a "**safe.txt**" file, used to store temporarily the processes allowed after the right password is used; if someone is able to erases it, it will be regenerated empty.

+ **How to prevent the tempering of the protection script?**

The better way is to set **proper permissions, both for the script execution and for its folder**. In general, it's better to include "***taskmgr***" and "***mmc***" in the controlled processes, so that the script cannot be stopped or disabled simply using Task Manager or Task Scheduler. Besides choosing unsuspected locations and foler names, it is also possibile, as shown above, to set a passfile and a passfolder (for which you have access permissions) to hinder the access to the "protection script" folder. Keeping the passfile outside the passfolder, will prevent *File Explorer* (not everything) to open that folder. This *weak* method can be applied by the protection script also to other folders even if no password and no process have been set to be checked (just press Enter when asked about them).

+ **What unusual behavior can be shown by the script?**

GuardShell and its possibile "protection script" combinations have been tested on Windows 10 Pro, also with **not admin accounts**, and they worked fine. It may happen that a controlled program is able to flash on the screen before get closed by the script and its password request; if you want to avoid that, reduce in the "protection script" the 5 seconds interval between password and/or passfile checks. If you set the "protection script" to run as scheduled task, consider it normal if you see PowerShell terminal appear for a moment at startup. On **Windows 11** it may not work properly.
