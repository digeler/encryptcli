#!/bin/bash
#echo login to azure
#az login 
#echo please copy and paste the correct sub 
#read $sub


az account set --subscription 928f4e7e-2c28-4063-a56e-6f1e6f2bb73c
echo az account get-access-token

echo logged in to azure 
echo starting .......



echo Enter name for keyvault resource group
read KVRG
echo Enter Location of RG
read loc
b=$(az group show -g $KVRG | grep name |  sed 's/"name"://')
k=$(echo $b |  tr -d '",')
 if [ ! -z "$k" ]
 	then 
 	echo "RG already exist will use thisname $k"

else 
	echo "RG not exist creating..."
	az group create -g $KVRG -l $loc

	fi
	
echo Enter kevault name 
read kvname
k=$(az keyvault show -g $KVRG -n $kvname | grep name) 
IFS=', ' read -r -a array <<< "$k"
sf=$(echo ${array[0]} | sed 's/\"//g')
if [ -z "$sf" ];
	then 
echo "KV not exist creating... with $kvname"
	#echo $(az account get-access-token)
	 #$(azure keyvault create --vault-name $kvname --resource-group $KVRG --location $loc)	
	 az keyvault create --name $kvname --resource-group $KVRG --location $loc --enabled-for-disk-encryption True 
    
    az keyvault show -n $kvname -g $KVRG
    echo sleeping 10 sec 
    sleep 10 

    echo creating KEK 
    
   echo $(az keyvault key create --vault-name $kvname --name mykeysub12 --protection software)
    
elif  [ "$sf" == "$kvname" ]
	echo $sf
	echo $kvname
then
echo "KV already exist will use this name $kvname"

 echo creating KEK 
    
   echo $(az keyvault key create --vault-name $kvname --name mykeysub12 --protection software)    
    
fi 

	




echo creating spn with password 


echo please write down the following details 
read sp_id sp_password <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

echo *********************************************
echo appid: $sp_id  
echo pass: $sp_password
echo *********************************************

echo "sleeping 10 sec for replication to complete"
sleep 10 
echo setting permissions 
az keyvault set-policy --name $kvname --spn $sp_id \
    --key-permissions wrapKey \
   --secret-permissions set

    echo encrypting vm please enter the following 
    

    read KEKV <<< $(az keyvault show -g $KVRG -n $kvname --query [id] -o tsv)

    read KEKUri <<< $(az keyvault key show --vault-name $kvname --name mykeysub12  --query [key.kid] -o tsv)
    echo vmname
    read vmname
    echo rg 
    read rg

    echo $rg
    echo $vmname
    
    sp=$(echo $sp_id)  
    pass=$(echo $sp_password)

    echo your appid is : $sp
    echo your password is : $pass


     az vm encryption enable --resource-group $rg --name $vmname --aad-client-id $sp --aad-client-secret $pass --key-encryption-keyvault $KEKV --key-encryption-key $KEKUri --disk-encryption-keyvault $KEKV --volume-type all --verbose
      # az vm show -g $rg -n $vmname
      # az vm encryption enable --resource-group $rg --name $vmname --aad-client-id 037a08c8-2811-4bd4-b2fd-ecf31c378dda --aad-client-secret 3e2d9636-bf42-4fb3-91ed-da192a5003ac --key-encryption-keyvault $KEKV --key-encryption-key $KEKUri --disk-encryption-keyvault $KEKV --volume-type all




