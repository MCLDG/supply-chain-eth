# Supply Chain on blockchain
Build a supply chain application on Ethereum

## Features supported
The supply chain application supports a number of features:

* Batches (Lots) of products are managed as ERC721 tokens
* The lifecycle of the batch is captured in the ERC721 token
* Facilities (locations) where processing takes place (i.e. where a trade item is transformed) are captured as BizLocations
* EPCIS events are applied to the trade item, such as COMMISSION, TRANSFORM, OBSERVE. The full EPCIS syntax is not used - only a subset
* Additional information can be captured against EPCIS events, such as IoT sensor data. This is not yet supported by EPCIS - it is WIP by one of the EPCIS working groups.
* Documents can be stored publicly on IPFS
* Documents can be stored privately using Kaleido storage, which uses S3 under the covers
* Documents can be transferred privately between specific members

## Getting started
Deploy Ethereum development dependencies:

* Node.js v10
* Truffle 
* Ganache 
* Metamask extension for Chrome
* Solidity syntax highlighting for VSCode.

## Deploying smart contracts

You have 4 options when deploying and testing your smart contracts:

1. Deploy to the test truffle network. This will run a local test Ethereum network:

```
truffle develop
```

After running this and seeing the accounts listed, you can use `compile, test or migrate` to compile and run your smart contract on this test network.

2. Ganache. On the command line, if you use the standard truffle commands, these will default to migrating to the local Ganache test network. For example, this will deploy to Ganache:

```
truffle migrate
truffle test
```

3. Kaleido. Your truffle-config.js should contain an entry for `quorum`, and it should point to the RPC endpoint for a specific Kaleido node, for example, FARMER_NODE_URL_RPC. You will also need a set of application credentials, which you generated in the Getting Started with Kaleido section. Execute the following to migrate your smart contract to Kaleido:

```
truffle migrate --network quorum
truffle test --network quorum
```

4. Use the Kaleido smart contract management feature, described below.

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
export CONSORTIUM_NAME=supply-chain
./create-consortium.sh
```

You might need to wait a minute or two for the nodes to be initialised. You can check the status of the nodes as follows. Once they show `"state": "started",` you can continue to populate the environment variables:

```
ENVIRONMENT_ID=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments" | jq -r ".[0]._id")
curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes" | jq
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

To generate applicatiton credentials for a specific member, run the following. For example, to generate app credentials for the FARMER member, use `export MEMBER_ID=$FARMER_MEMBER_ID`:

```
export MEMBER_ID=<member ID>
source ./generate-app-credentials.sh
```

Now you can construct a full URL for JSON/RPC calls. Note that the administrative/operational API can be called using the API Key as an authentication mechanism, but application specific APIs must be called using application credentials that are generated for the specific member. This example assumes you have used the MEMBER_ID for the Farmer when generating app credentials above:

```
export FARMER_CREDS_USERNAME=$CREDS_USERNAME
export FARMER_CREDS_PASSWORD=$CREDS_PASSWORD
export FARMER_FULL_URL=https://${FARMER_CREDS_USERNAME}:${FARMER_CREDS_PASSWORD}@${FARMER_NODE_URL_RPC:8}
```

Make a test call using the full URL. You may not see a payload in the response, but the request should succeed without failing the authorization check:

```
curl -v $FARMER_FULL_URL/api/v1/wallets
```

## Restarting your terminal session
If you restart your terminal session you'll lose all the environment variables. Here is how to re-populate them:

Hopefully you stored your API key somewhere safe. If not, you can create another one in the Kaleido console, under `Account->API Keys`.

```
export APIKEY="YOUR_API_KEY"
export CONSORTIUM_NAME=name
```

Then export other variables:

```
cd IaC
source ./env-kaleido.sh
source ./env-consortium.sh
```

You can reuse the app credentials you created earlier. If you have lost them, you can regenerate them:

```
source ./generate-app-credentials.sh
```

Now you can construct a full URL for JSON/RPC calls. This example assumes you have used the MEMBER_ID for the Farmer when generating app credentials above:

```
export FARMER_CREDS_USERNAME=$CREDS_USERNAME
export FARMER_CREDS_PASSWORD=$CREDS_PASSWORD
export FARMER_FULL_URL=https://${FARMER_CREDS_USERNAME}:${FARMER_CREDS_PASSWORD}@${FARMER_NODE_URL_RPC:8}
curl --verbose $FARMER_FULL_URL/api/v1/wallets
```

## Managing smart contracts in Kaleido

Kaleido supports a smart contract management solution that can manage packaging, tracking and promoting smart contracts through different environments. It does not (yet) support a ci/cd approach, where a change to the source would trigger a build, nor does it support a workflow, where a particular compilation would be promoted in order through DEV, TEST, UAT, PROD. However, it does allow you to trace which transactions were executed against a specific smart contract, and tie these back to the exact commit in Github. Once you have tested a specific compilation of a smart contract in DEV, you could (manually) promote the same version of that smart contract to TEST. Kaleido does hash the smart contract code, so it prevents you from running two identical versions of the same smart contract in the same environment.

Compile the package-labels smart contract. This compiles the solidity code and stores it ready for promotion to specific environments. Compiling produces the bytecode, application binary interface (ABI), and developer docs. It also maintains a pointer back to the exact source code version (the commit):

```
cd IaC
source ./create-contract-for-packagelabels.sh
```

Promote the package-labels smart contract to an environment. This stores the smart contract in the Kaleido registry along with the bytecode, application binary interface (ABI), and developer docs. Once it is stored in the registry, a REST API is generated and available to all nodes. It can be used to interact with the smart contract. The smart contract is not instantiated during promotion.:

```
cd IaC
source ./promote-contract-for-packagelabels.sh
```

As the smart contract is promoted, Kaleido will auto-generate a RESTful API. You can use the RESTful API to access all the functions in your smart contract. To do this, use the Kaleido console and navigate to the Contract Project you created when you ran this script `create-contract-for-packagelabels.sh`. You should see an associated Compilation at the bottom of the console page, with a status of Complete. Select this. When you ran `deploy-contract-for-packagelabels.sh` above, this should have promoted your smart contract to a Kaleido environment - you will see this in the Kaleido console on the Compilation Details page, under the heading: `Promoted to Environments - (Endpoint)`. Select `View API Gateway` and enter your application credentials, then select `View API` to open the API Gateway console.

You should see all the functions, public variables, events and constructor for your smart contract. You will need to instantiate the smart contract first, so find the constructor, populate any expected variables in the BODY DATA section, and click TRY. This will instantiate your smart contract on the Kaleido network and return the contract address in the JSON response. You will use this in the other REST calls to call the appropriate contract. If you lose it, you can find it in the Kaleido console under your Kaleido environment, in the GATEWAY APIS tab.

You can also download the Swagger JSON spec from the console if you need it.

## Using IPFS

Instructions and background information on IPFS can be found here: https://docs.kaleido.io/kaleido-services/ipfs/

To run an IPFS node in Kaleido:

```
source create-ipfs-node.sh
```

To upload a file to IPFS, specify a file name (using the absolute path):

```
export FILE_PATH_TO_UPLOAD=/Users/edgema/Documents/apps/non-profit-blockchain/LICENSE
source upload-file-ipfs.sh
```

To download a file from IPFS:

```
export FILE_PATH_TO_DOWNLOAD=/Users/edgema/Downloads/test
export IPFS_DOWNLOAD_HASH=<hash number from the upload to IPFS call>
./download-file-ipfs.sh
```

## Using Kaleido ID registry service
Kaleido registry service is used by a number of other Kaleido services, such as the Storage service. 

```
source create-registry-service.sh
```

## Using Kaleido storage
Kaleido storage can be used to securely send off-chain data between members in the network. For example, it's possible to store a document in off-chain storage for MemberA and share this document with MemberB. The document is encrypted with memberB's public cert, and digitally signed with MemberA's private cert. This is great for PII data that should NOT be stored on-chain, yet requires strict controls on who can view/update it. Options on where the file is stored are either Kaleido storage or Cloud storage. In this case we are using Cloud storage, which uses S3 for storage.

```
export REGION=us-east-1
export FARMER_STORAGE_BUCKET=your bucket name for the Kaleido storage service
export AWS_USER_ID=your AWS user ID
export AWS_USER_SECRET=your AWS user secret
source create-storage-service.sh
```

Make sure you have created the Kaleido registry service above before continuing.

To upload a file to Document Storage, specify a file path (using the absolute path), and the file name to be used in the document storage service. Note that the API endpoint for the document service is different - it is not the standard Kaleido endpoint, but an endpoint specific to the service itself. The endpoint can be found in the output from the create service (which we ran above), or in the Kaleido console (under the service), or you could query /services and find it there. I do populate the API endpoint in ./env-consortium.sh:

```
export FILE_PATH_TO_UPLOAD=/Users/edgema/Documents/apps/non-profit-blockchain/LICENSE
export FILE_NAME=LICENSE
source upload-file-document-storage.sh
```

## Transferring files to other members using Kaleido storage
This requires the registry service to be deployed, and for your member (org) to register its identity on-chain. There is a script to create the registry service (./create-registry-service.sh), but you will need to use either the Kaleido console or the Kaleido CLI to register identities on chain. I'm using the console. Instructions are here. You should register the identity, and create destinations for FARMER and SHIPPER, to allow them to share docs:

https://docs.kaleido.io/kaleido-services/document-store/destinations/

```
export FARMER_DEST=kld://documentstore/m/u0yjymivae/e/u0x83bqeuj/s/u0v9kzyj82/d/farmer-dest
export SHIPPER_DEST=kld://documentstore/m/u0yjymivae/e/u0x83bqeuj/s/u0v9kzyj82/d/shipper-dest
export FILE_NAME=LICENSE
source transfer-file-document-storage.sh
```

Note that the transfer via the API does not work. I have raised an issue with Kaleido. Via the console it works fine.

## Representing a micro-batch as an ERC721 token

We'll use the open zepellin library to help us setup the ERC721 token (https://github.com/OpenZeppelin/openzeppelin-contracts). Either install it or add it to package.json and run 'npm install'.

```
npm install openzeppelin-solidity
```

Deploy the LotContract smart contract.

Use truffle to test it:

```
truffle console
```

In the console

```
let contract = await LotContract.deployed()
contract.address
contract.totalSupply()
let accounts = await web3.eth.getAccounts()

contract.setBatchWeightInKg(500)
contract.batchWeightInKg()
#create one token and transfer it
contract._mint(accounts[0]);
contract.totalSupply();
contract.ownerOf(1);
contract.safeTransferFrom(accounts[0] , accounts[1], 1);
contract.ownerOf(1);

#create another token and transfer it
contract._mint(accounts[1]);
contract.totalSupply();
contract.ownerOf(2);
contract.safeTransferFrom(accounts[1] , accounts[0], 2);
contract.ownerOf(2);

#update the batch with a weight
contract.batchWeightInKg()
contract.setBatchWeightInKg(500)
contract.batchWeightInKg()

```















