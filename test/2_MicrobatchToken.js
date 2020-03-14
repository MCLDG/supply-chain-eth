const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");
const BizLocation = artifacts.require("./BizLocation.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;
  let bizLocation;
  const harvestedCrop1TokenId = 1;
  const harvestedCrop2TokenId = 2;
  const packagingTokenId = 3;
  const labellingTokenId = 4;
  const glnBizLocationFarm1 = 123; // as used in BizLocation.js, represents the farm
  const glnBizLocationFarm2 = 123; // as used in BizLocation.js, represents the farm
  const glnBizLocationCoop = 456; // as used in BizLocation.js, represents the co-op
  const glnBizLocationPackaging = 789; // as used in BizLocation.js, represents the Packaging manufacturer
  const glnBizLocationLabel = 012; // as used in BizLocation.js, represents the Label manufacturer
  const farmer1Account = accounts[0];
  const farmer2Account = accounts[1];
  const coopAccount = accounts[2];
  const shipperAccount = accounts[4];
  const packagingAccount = accounts[5];
  const labellerAccount = accounts[6];
  const roasterAccount = accounts[7];

  before(async () => {
    microbatchToken = await MicrobatchToken.deployed()
    bizLocation = await BizLocation.deployed()
    console.log("ACCOUNTS")
    console.log(accounts)
  })

  describe('deployment-bizLocation', async () => {
    it('bizLocation deploys and initialises successfully', async () => {
      const address = await bizLocation.address
      assert.notEqual(address, ZERO_ADDRESS)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can add a bizLocation for the Farm', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocationFarm1, "Pacamara Farm", "Organic coffee farm producing pacamara coffee beans", true, true, "1504 Stone Ave, Gold Coast");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocationFarm1)
      });
    })

    it('can add a bizLocation for the Co-op', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocationCoop, "Charlie Co-op", "Organic co-op for washing and drying coffee beans", true, false, "Unit A, Portland Mountain Road, Gold Coast");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocationCoop)
      });
    })

    it('can add a bizLocation for packaging', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocationPackaging, "Peters Packaging", "Environmental and sustainable packaging", true, true, "Unit P, Serengeti, Finland");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocationPackaging)
      });
    })

    it('can add a bizLocation for labels', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocationLabel, "Lucinders Labels", "Environmental, compostable and sustainable labels", true, true, "Unit L, Munich, Germany");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocationLabel)
      });
    })

    it('can query a bizLocation that was previously added', async () => {
      const bizLocationDetail = await bizLocation.get(glnBizLocationCoop);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.assetCommission, false)
    })
  })

  describe('deployment-microbatchToken', async () => {

    it('microbatchToken deploys and initialises successfully', async () => {
      const address = await microbatchToken.address
      assert.notEqual(address, ZERO_ADDRESS)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 0)
      const name = await microbatchToken.name()
      const symbol = await microbatchToken.symbol()
      assert.equal(name, "MICROBATCH")
      assert.equal(symbol, "MBAT")
    })

    it('can set the address of the Facilties smart contract', async () => {
      microbatchToken.setBizLocationAddress(bizLocation.address);
    })

    it('can query a bizLocation added during testing of the Facilties smart contract', async () => {
      const bizLocationDetail = await bizLocation.get(glnBizLocationCoop);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.assetCommission, false)
    })

    it('can mint a new token', async () => {
      const receipt = await microbatchToken.mint(farmer1Account);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: farmer1Account, tokenId: new BN(harvestedCrop1TokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 1)
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, farmer1Account)
    })

    it('prior to commissioning an asset it should have no events', async () => {
      const numberOfEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop1TokenId)
      assert.equal(numberOfEvents, 0)
    })

    it('prior to commissioning an asset it should have no existing commissioned assets', async () => {
      await expectRevert(microbatchToken.getCommissionedAsset(harvestedCrop1TokenId), "No assets exist for this token");
    })

    it('can commission an asset on the newly minted token', async () => {
      const receipt = await microbatchToken.commissionAsset(harvestedCrop1TokenId, glnBizLocationFarm1, "harvested", "kg", 500)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: farmer1Account, tokenId: new BN(harvestedCrop1TokenId), action: "COMMISSION", bizStep: "harvested", bizLocationId: new BN(glnBizLocationFarm1), inputQuantity: new BN(500), outputQuantity: new BN(500)
      });
    })

    it('newly commissioned asset should have only 1 event', async () => {
      const numberOfEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop1TokenId)
      assert.equal(numberOfEvents, 1)
    })

    it('cannot commission a second asset on the newly minted token. Only 1 commissioned asset per token', async () => {
      await expectRevert(microbatchToken.commissionAsset(harvestedCrop1TokenId, glnBizLocationFarm1, "harvested", "kg", 500), "This tokenId contains a commissioned asset. Assets can be commissioned once");
    })

    it('can transfer token from one account to another', async () => {
      const receipt = await microbatchToken.safeTransferFrom(farmer1Account, coopAccount, harvestedCrop1TokenId);
      expectEvent(receipt, 'Transfer', {
        from: farmer1Account, to: coopAccount, tokenId: new BN(harvestedCrop1TokenId)
      });
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, coopAccount)
      assert.notEqual(owner, farmer1Account)
    })

    it('cannot transfer a token the account does not own', async () => {
      await expectRevert(microbatchToken.safeTransferFrom(farmer1Account, coopAccount, harvestedCrop1TokenId), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot transfer a token unless the transfer caller is the token owner (differs from the token holder)', async () => {
      await expectRevert(microbatchToken.safeTransferFrom(coopAccount, shipperAccount, harvestedCrop1TokenId), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot approve transferring a token when the account does not own the token', async () => {
      await expectRevert(microbatchToken.approve(shipperAccount, harvestedCrop1TokenId), "ERC721: approve caller is not owner nor approved for all");
    })

    it('cannot approve the transfer of a token if the token holder and approve account are equal', async () => {
      await expectRevert(microbatchToken.approve(coopAccount, harvestedCrop1TokenId), "ERC721: approval to current owner");
    })

    it('can approve another account to transfer a token if account is the token owner', async () => {
      await microbatchToken.approve(shipperAccount, harvestedCrop1TokenId, { from: coopAccount });
    })

    it('can transfer token from one account to another using an approved account, i.e. transfer caller is not the token holder', async () => {
      const receipt = await microbatchToken.safeTransferFrom(coopAccount, shipperAccount, harvestedCrop1TokenId, { from: shipperAccount });
      expectEvent(receipt, 'Transfer', {
        from: coopAccount, to: shipperAccount, tokenId: new BN(harvestedCrop1TokenId)
      });
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, shipperAccount)
      assert.notEqual(owner, coopAccount)
    })

    it('can mint a second token', async () => {
      const receipt = await microbatchToken.mint(farmer2Account);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: farmer2Account, tokenId: new BN(harvestedCrop2TokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 2)
      const owner = await microbatchToken.ownerOf(2)
      assert.equal(owner, farmer2Account)
    })

    it('can commission an asset on the second token', async () => {
      const receipt = await microbatchToken.commissionAsset(harvestedCrop2TokenId, glnBizLocationFarm2, "harvested", "kg", 490)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: farmer2Account, tokenId: new BN(harvestedCrop2TokenId), action: "COMMISSION", bizStep: "harvested", bizLocationId: new BN(glnBizLocationFarm2), inputQuantity: new BN(490), outputQuantity: new BN(490)
      });
    })

    it('each token is associated with a different asset', async () => {
      let asset = await microbatchToken.getCommissionedAsset(harvestedCrop1TokenId)
      assert.equal(asset[0], harvestedCrop1TokenId)
      assert.equal(asset[2], glnBizLocationFarm1)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 500)

      asset = await microbatchToken.getCommissionedAsset(harvestedCrop2TokenId)
      assert.equal(asset[0], harvestedCrop2TokenId)
      assert.equal(asset[2], glnBizLocationFarm2)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 490)
    })

    // A co-op does not produce assets. It takes as input an asset, raw beans, and transforms it to washed and dried beans
    // It can therefore not be used as a bizLocation that creates new assets
    it('cannot associate an asset created in a bizLocation that does not produce assets', async () => {
      await expectRevert(microbatchToken.commissionAsset(harvestedCrop2TokenId, glnBizLocationCoop, "drying", "kg", 500), "Assets can only be created at facilities that produce/commission raw assets");
    })

    // Transform an asset, i.e. from raw coffee beans to dried beans
    it('can transform an asset', async () => {
      const receipt = await microbatchToken.transformAsset(harvestedCrop2TokenId, glnBizLocationCoop, "drying", "kg", 490, 440)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: farmer2Account, tokenId: new BN(harvestedCrop2TokenId), action: "TRANSFORM", bizStep: "drying", bizLocationId: new BN(glnBizLocationCoop), inputQuantity: new BN(490), outputQuantity: new BN(440)
      });
    })

    it('can get the event history of an asset', async () => {
      const history = await microbatchToken.getEventHistory(harvestedCrop2TokenId)
      assert.equal(history[0], harvestedCrop2TokenId)
      assert.equal(history[2], glnBizLocationCoop)
      assert.equal(history[3], "drying")
      assert.equal(history[5], 440)
    })

    it('can observe an asset', async () => {
      let numberEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop2TokenId)
      assert.equal(numberEvents, 2)
      const receipt = await microbatchToken.observeAsset(harvestedCrop2TokenId, glnBizLocationCoop, "drying", "kg", 440, "")
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: farmer2Account, tokenId: new BN(harvestedCrop2TokenId), action: "OBSERVE", bizStep: "drying", bizLocationId: new BN(glnBizLocationCoop), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop2TokenId)
      assert.equal(numberEvents, 3)
    })

    it('can attach sensor data to an asset during an observe event', async () => {
      let numberEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop2TokenId)
      assert.equal(numberEvents, 3)
      const receipt = await microbatchToken.observeAsset(harvestedCrop2TokenId, glnBizLocationCoop, "drying", "kg", 440,
        '{"infoTypeURI": "urn:type:sensor:v2", "sensorType": "temperature", "reading": "25.457", "timestamp": "2020-02-28T14:32:00Z"}');
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: farmer2Account, tokenId: new BN(harvestedCrop2TokenId), action: "OBSERVE", bizStep: "drying", bizLocationId: new BN(glnBizLocationCoop), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await microbatchToken.getNumberEventsForTokenAsset(harvestedCrop2TokenId)
      assert.equal(numberEvents, 4)
    })

    it('can get events recorded against an asset', async () => {
      let assetEvent = await microbatchToken.getAssetEventByIndex(harvestedCrop2TokenId, 0)
      assert.equal(assetEvent[0], harvestedCrop2TokenId)
      assert.equal(assetEvent[1], "")
      assert.equal(assetEvent[3], "harvested")

      assetEvent = await microbatchToken.getAssetEventByIndex(harvestedCrop2TokenId, 3)
      assert.equal(assetEvent[0], harvestedCrop2TokenId)
      assert.equal(assetEvent[1], '{"infoTypeURI": "urn:type:sensor:v2", "sensorType": "temperature", "reading": "25.457", "timestamp": "2020-02-28T14:32:00Z"}')
      assert.equal(assetEvent[3], "drying")
    })

    // Can support packaging and labels as an asset
    it('can mint a token to hold a batch of Packaging assets', async () => {
      const receipt = await microbatchToken.mint(packagingAccount);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: packagingAccount, tokenId: new BN(packagingTokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 3)
      const owner = await microbatchToken.ownerOf(packagingTokenId)
      assert.equal(owner, packagingAccount)
    })

    // The asset below is created with an empty UOM. According to EPCIS, if UOM is empty, the quantity field contains a count of items (in this case, 1,000 packages)
    it('can commission an asset representing the batch of packaging', async () => {
      const receipt = await microbatchToken.commissionAsset(packagingTokenId, glnBizLocationPackaging, "batch of packaging", "", 1000)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: packagingAccount, tokenId: new BN(packagingTokenId), action: "COMMISSION", bizStep: "batch of packaging", bizLocationId: new BN(glnBizLocationPackaging), inputQuantity: new BN(1000), outputQuantity: new BN(1000)
      });
    })

    it('can mint a token to hold a batch of Label assets', async () => {
      const receipt = await microbatchToken.mint(labellerAccount);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: labellerAccount, tokenId: new BN(labellingTokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 4)
      const owner = await microbatchToken.ownerOf(labellingTokenId)
      assert.equal(owner, labellerAccount)
    })

    // The asset below is created with an empty UOM. According to EPCIS, if UOM is empty, the quantity field contains a count of items (in this case, 1,000 packages)
    it('can commission an asset representing the batch of labels', async () => {
      const receipt = await microbatchToken.commissionAsset(labellingTokenId, glnBizLocationLabel, "batch of labels", "", 2000)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: labellerAccount, tokenId: new BN(labellingTokenId), action: "COMMISSION", bizStep: "batch of labels", bizLocationId: new BN(glnBizLocationLabel), inputQuantity: new BN(2000), outputQuantity: new BN(2000)
      });
    })

    // Test the entire process, from commissioning an asset, progressing it through transforms and observes, 
    // and finally aggregating it into a packaged product
  })

})
