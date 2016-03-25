#### ssh 无密码登录  
A机器无密码登录到B机器，需要将A机器的公钥(id_rsa.pub)放到B机器的.ssh/authorized_keys文件里  
ssh-copy-id 将A机器的id_rsa.pub写到B机器的 ~/ .ssh/authorized_key.文件中  
---  
ssh-copy-id -i ~/.ssh/id_rsa.pub B_ip  

如果没有 ssh-copy-id 可以用如下命令:  
---  
cat ~/.ssh/id_dsa.pub | ssh user@slave "umask 077; mkdir -p .ssh ; cat >> .ssh/authorized_keys"  

  






 

