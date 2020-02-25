# Supply Chain on blockchain
Build a supply chain application on Ethereum

## Getting started
Deploy Ethereum development dependencies:

Node.js
Truffle:
npm install -g truffle
Ganache (local Ethereum blockchain for testing):
https://github.com/trufflesuite/ganache/releases
Select a release and scroll down to download the appropriate binary


Metamask extension for Chrome:

I've also added Solidity syntax highlighting to VSCode.

In a new directory for your application, initialise a new truffle project:

```
truffle init
```

Configure package.json with the appropriate packages, then install them:

```
npm install
```
## Getting started with Kaleido

We will use IaC (infra as code) to create all the necessary Kaleido components. All API calls to Kaleido require an API key, which is used as an authorisation token when making API calls. You'll need to access the Kaleido console to generate the API key. Select `Account->API Keys`, and click `+ New API Key`. Store your API key somewhere safe, such as in a password manager. Do NOT store it in any file that could end up in the GitHub repo.

Setup the appropriate environment variables to make life easier for future steps. First, export your API key (which you saved in the previous step):

```
export APIKEY="YOUR_API_KEY"
```

Then export other variables:

```
cd IaC
source ./env-kaleido.sh
echo API URL is $APIURL
``` 

Create the Kaleido consortium:

```
./create-consortium
```

Populate all the environment variables we will use. Make sure the consortium name is populated. 

```
echo $CONSORTIUM_NAME
```

If it is not populated, populate it manually by finding the name in the Kaleido console:

```
export CONSORTIUM_NAME=name
```

Now populate the environment variables:

```
source ./env-consortium.sh
```

To generate applicatiton credentials for a specific member, run the following:

```
export MEMBER_ID=<member ID>
source ./generate-app-credentials.sh
```

Now you can construct a full URL for JSON/RPC calls. This example assumes you have used the MEMBER_ID for the Farmer when generating app credentials above:

```
export FARMER_CREDS_USERNAME=$CREDS_USERNAME
export FARMER_CREDS_PASSWORD=$CREDS_PASSWORD
export FARMER_FULL_URL=https://${FARMER_CREDS_USERNAME}:${FARMER_CREDS_PASSWORD}@${FARMER_NODE_URL_RPC:8}
```

Make a test call using the full URL:

```
curl -v $FARMER_FULL_URL/api/v1/wallets
```

## Deploying smart contracts

You have 3 options when deploying your smart contracts:

1. Deploy to the test truffle network. This will run a local test Ethereum network:

```
truffle develop
```

After running this and seeing the accounts listed, you can use `compile, test or migrate` to compile and run your smart contract on this test network.

2. Ganache. On the command line, if you use the standard truffle commands, these will default to migrating to the local Ganache test network. For example, this will deploy to Ganache:

```
truffle migrate
```

3. Kaleido. Your truffle-config.js should contain an entry for `quorum`. Execute the following to migrate your smart contract to Kaleido:

```
truffle migrate --network quorum
```

## Managing smart contracts in Kaleido

Kaleido supports a smart contract management solution that can manage deploying, packaging, tracking and promoting smart contracts through different environments.

To compile the package-labels smart contract:

```
cd IaC
source ./create-contract-for-packagelabels.sh
```

To deploy the package-labels smart contract:

```
cd IaC
source ./deploy-contract-for-packagelabels.sh
```














