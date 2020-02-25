echo Installing jq
brew install jq

#############################################################################################################
echo Creating Kaleido CONSORTIUM
#############################################################################################################
CONSORTIUM=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"supply-chain\", \
    \"description\": \"Supply chain CONSORTIUM\" \
  }" \
  "$APIURL/consortia" | jq)

CONSORTIUM_ID=$(echo $CONSORTIUM | jq -r "._id")
echo Created Kaleido consortium with id: $CONSORTIUM_ID

CONSORTIUM=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID" | jq)

CONSORTIUM_NAME=$(echo $CONSORTIUM | jq -r ".name")
CONSORTIUM_ID=$(echo $CONSORTIUM | jq -r "._id")
echo Created Kaleido consortium with name: $CONSORTIUM_NAME, id: $CONSORTIUM_ID
 
#############################################################################################################
echo Creating Kaleido environment
#############################################################################################################
ENVIRONMENT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"Supply Chain Environment\", \
    \"provider\": \"quorum\", \
    \"consensus_type\": \"ibft\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/environments" | jq)

ENVIRONMENT_ID=$(echo $ENVIRONMENT | jq -r "._id")

ENVIRONMENT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID" | jq)

ENVIRONMENT_NAME=$(echo $ENVIRONMENT | jq -r ".name")
ENVIRONMENT_ID=$(echo $ENVIRONMENT | jq -r "._id")
echo Created Kaleido environment with name: $ENVIRONMENT_NAME, id: $ENVIRONMENT_ID

#############################################################################################################
echo Creating member - Farmer
#############################################################################################################

FARMER=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"org_name\": \"Farmer\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/memberships" | jq)

FARMER_MEMBER_NAME=$(echo $FARMER | jq -r ".org_name")
FARMER_MEMBER_ID=$(echo $FARMER | jq -r "._id")
echo Created Kaleido member with name: $FARMER_MEMBER_NAME, id: $FARMER_MEMBER_ID

#############################################################################################################
echo Creating member - Co-op
#############################################################################################################

COOP=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"org_name\": \"Co-op\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/memberships" | jq)

COOP_MEMBER_NAME=$(echo $COOP | jq -r ".org_name")
COOP_MEMBER_ID=$(echo $COOP | jq -r "._id")
echo Created Kaleido member with name: $COOP_MEMBER_NAME, id: $COOP_MEMBER_ID

#############################################################################################################
echo Creating member - Shipper
#############################################################################################################
SHIPPER=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"org_name\": \"Shipper\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/memberships" | jq)

SHIPPER_MEMBER_NAME=$(echo $SHIPPER | jq -r ".org_name")
SHIPPER_MEMBER_ID=$(echo $SHIPPER | jq -r "._id")
echo Created Kaleido member with name: $SHIPPER_MEMBER_NAME, id: $SHIPPER_MEMBER_ID

#############################################################################################################
echo Creating a node for Farmer
#############################################################################################################
FARMER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"membership_id\": \"$FARMER_MEMBER_ID\", \
    \"name\": \"FarmerNode\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes" | jq)

FARMER_NODE_ID=$(echo $FARMER_NODE | jq -r "._id")
echo Created Kaleido node with id: $FARMER_NODE_ID

#############################################################################################################
echo Creating a node for Co-op
#############################################################################################################
COOP_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"membership_id\": \"$COOP_MEMBER_ID\", \
    \"name\": \"CoopNode\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes" | jq)

COOP_NODE_ID=$(echo $COOP_NODE | jq -r "._id")
echo Created Kaleido node with id: $COOP_NODE_ID

#############################################################################################################
echo Creating a node for Shipper
#############################################################################################################
SHIPPER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"membership_id\": \"$SHIPPER_MEMBER_ID\", \
    \"name\": \"ShipperNode\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes" | jq)

SHIPPER_NODE_ID=$(echo $SHIPPER_NODE | jq -r "._id")
echo Created Kaleido node with id: $SHIPPER_NODE_ID
