function GetDefaultSubscriptionId () {
    $subscriptionString = $(az account list) -join ' '
    Write-Debug $subscriptionString

    $subscriptionObj = ConvertFrom-Json $subscriptionString

    foreach ($item in $subscriptionObj) {
        Write-Debug $item
        if ($item.isDefault) {
            $defaultSubscriptionId = $item.id
        } else {
            Write-Output "Not default"
        }
    }

    Write-Debug "Default subscription id: $defaultSubscriptionId"
    return $defaultSubscriptionId
}

function CreateTerraformCredentials ($SubscrptionId) {
    $credCreateOutput = $(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SubscrptionId}")
    $credentialsString = $credCreateOutput -join ' '
    Write-Debug "Credentials created $credentialsString"
    $credentialsObject = ConvertFrom-Json $credentialsString
    return $credentialsObject
}

function DisplayServicePrincipal ($spName) {
    $(az ad sp show --id "$spName")
}

function DisplayAzureCliPrincipals () {
    $(az ad sp list --query "[?starts_with(displayName, 'azure-cli-')]")
}

#TERRAFORM
function SetTerraformCredentials ($subscriptionId, $spCredentials) {
    if (!($Env:ARM_SUBSCRIPTION_ID -eq $NULL)) {
        Write-Output "Subcription is already set: $Env:ARM_SUBSCRIPTION_ID"
    }
    if (!($Env:ARM_CLIENT_ID -eq $NULL)) {
        Write-Output "Client id is already set: $Env:ARM_CLIENT_ID"
    }
    if (!($Env:ARM_CLIENT_SECRET -eq $NULL)) {
        Write-Output "Secret is already set: $Env:ARM_CLIENT_SECRET"
    }
    if (!($Env:ARM_TENANT_ID -eq $NULL)) {
        Write-Output "Tenant is already set: $Env:ARM_TENANT_ID"
    }

    $Env:ARM_SUBSCRIPTION_ID = $subscriptionId

    $Env:ARM_CLIENT_ID = $spCredentials.appId
    $Env:ARM_CLIENT_SECRET = $spCredentials.password
    $Env:ARM_TENANT_ID = $spCredentials.tenant
}

$sId = GetDefaultSubscriptionId
Write-Output "Default subscription ID is $sId"
Write-Output "Creating service principal"
$newCredentials = CreateTerraformCredentials($sId)
SetTerraformCredentials $sId $newCredentials

Get-ChildItem Env: | Sort Name