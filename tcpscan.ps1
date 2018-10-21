cls
echo "==================================================================="
echo "A Simple port test script with a pseudo OS detection" 
echo "You can detect OS, only if you have permission to remote OS :)"
echo "Bonus, FTP weak password check function added "
echo "USAGE:Just change the ports range variable and endpoint IP addresses to scan your own network "
echo "==================================================================="

$ports=@(135,21,80)

$endPoint=@(
'192.168.1.11',
'192.168.1.100'
,'192.168.1.109',
'192.168.1.14',
'192.168.1.119'
)

$users=@('abakus','foobar','potato','johny_bravo','pandwoo','victim1','victim2')
$passwords=@('grthyu76uyrkyu','rthytetytuyuyiuyiyt','pazzword','qwerty123','victimpassword123')



echo "Please wait trying to identify your local IP address"

try{
$ipa=Get-NetIPConfiguration | ?{$_.interfacealias  -and $_.ipv4defaultgateway -ne $null`
-and $_.netadapter.status -ne 'Disconnected'} | select ipv4address 
$localhost=$ipa.ipv4address | select -ExpandProperty ipaddress
echo "OK! your local IP identified $($ipa.ipv4address | select -ExpandProperty ipaddress)"
} catch {echo "Unable to identify your local IP :("}



function isAlive?{

$ping = New-Object System.Net.NetworkInformation.Ping

foreach($end in $endPoint){
    $open=@()

    $ping_status=$ping.Send($end)
    
    if($ping_status.Status -eq 'Success') {
        
        echo "-----------------------------------------"
        Write-Host "$end is alive" -BackgroundColor DarkBlue -ForegroundColor yellow
        
        
            if ($ping_status.Address -eq $localhost){
                
                
                    $obj= $(Get-WmiObject `
                    -ComputerName $end win32_operatingsystem |select `
                    caption,version,csname,osarchitecture)
                    identity? $obj


                
        
                } else { 
                        try {
                            $cred=Get-Credential ''
                            
                            $obj= $(Get-WmiObject `
                            -ComputerName $end win32_operatingsystem -Credential $cred -ErrorAction SilentlyContinue |select `
                            caption,version,csname,osarchitecture)
                            identity? $obj
                            #echo "Your OS: $(Get-WmiObject -ComputerName $end -Credential $cred win32_operatingsystem -ErrorAction SilentlyContinue | select -ExpandProperty caption)"
            
                            }
                            catch{ 
                                $err = $_.Exception.Message 
                                echo "UNKNOWN OS or incorrect USER/PASSWORD"
                            }
            }


       portCheck 
        
        
        

    }else{
        echo "----------------------------------------"
        Write-Host "$end $($ping_status.Status) " -BackgroundColor red
        
    }
    
    

}


}


function portCheck{


foreach($p in $ports){
    
    $rpc=new-object System.Net.Sockets.TcpClient
        try {
             $rpc.Connect($end,$p)
             echo "PORT $p on $end IS OPEN"
             if ($p -eq 21){
                echo "Checking for WEAK password in FTP services"
                weak_ftp_pass
             }
                
             
        
        }catch{
              $err = $_.Exception.Message
              
              echo "PORT $p on $end IS CLOSED "
              #echo "error $err"
              
        }
    $rpc.close()
    
    } 

}

function weak_ftp_pass{
    foreach($user in $users){
        foreach($pass in $passwords){
            
            try
                    {
                        $ftpRequest = [System.Net.FtpWebRequest]::Create("ftp://"+$end)
                        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
                        #echo "Checking $user : $pass"
                        #sleep 1
                        $ftpRequest.Credentials = new-object System.Net.NetworkCredential($user, $pass)
                        $result = $ftpRequest.GetResponse()
                        $message = $result.BannerMessage + $result.WelcomeMessage
                        
                        Write-Host "Match found! for $user : $Pass" -BackgroundColor White -ForegroundColor Black
                        
                        #break #uncomment if you just need 1 password
                    }

                    catch
                    {
                        $err_ftp = $_.Exception.message
                        #echo "$err_ftp" 
}
        
        }
    
    }echo ""
     echo "======= FTP BANNER START ==========="
     echo "$message"
     echo "======= FTP BANNER END ==========="
     echo ""


}

function identity? {
                    param(
                    [Parameter(Mandatory=$true)]$obj
                    )
                    

                    $os_properties=New-Object -TypeName psobject -Property @{
                        OS=$obj.caption
                        Version=$obj.version
                        Arch=$obj.osarchitecture
                        Hostname=$obj.csname
                    }
                
                   echo "==========================================="
                   echo "$os_properties" 
                   echo "==========================================="
}

   isAlive?
