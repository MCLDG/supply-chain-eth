const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");
const BizLocation = artifacts.require("./BizLocation.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;
  let bizLocation;
  const firstTokenId = 1;
  const secondTokenId = 2;
  const glnBizLocation1 = 123; // as used in BizLocation.js, represents the farm
  const glnBizLocation2 = 456; // as used in BizLocation.js, represents the co-op

  before(async () => {
    microbatchToken = await MicrobatchToken.deployed()
    bizLocation = await BizLocation.deployed()
    console.log("ACCOUNTS")
    console.log(accounts)
  })

  describe('deployment-bizLocation', async () => {
    it('bizLocation deploys and initialises successfully', async () => {
      const address = await bizLocation.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can add a new bizLocation', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocation1, "Pacamara Farm", "Organic coffee farm producing pacamara coffee beans", true, true, "1504 Stone Ave, Gold Coast");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocation1)
      });
    })

    it('can add a second bizLocation', async () => {
      const receipt = await bizLocation.createBizLocation(glnBizLocation2, "Charlie Co-op", "Organic co-op for washing and drying coffee beans", true, false, "Unit A, Portland Mountain Road, Gold Coast");
      expectEvent(receipt, 'bizLocationEvent', {
        gln: new BN(glnBizLocation2)
      });
    })

    it('can query a bizLocation that was previously added', async () => {
      const bizLocationDetail = await bizLocation.get(glnBizLocation2);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.assetCommission, false)
    })
  })

  describe('deployment-microbatchToken', async () => {
    it('microbatchToken deploys and initialises successfully', async () => {
      const address = await microbatchToken.address
      assert.notEqual(address, 0x0)
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
      const bizLocationDetail = await bizLocation.get(glnBizLocation2);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.assetCommission, false)
    })

    it('can mint a new token', async () => {
      const receipt = await microbatchToken._mint(accounts[0]);
      expectEvent(receipt, 'Transfer', {
        from: "0x0000000000000000000000000000000000000000", to: accounts[0], tokenId: new BN(firstTokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 1)
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[0])
    })

    it('prior to commissioning an asset it should have no events', async () => {
      const numberOfEvents = await microbatchToken.getNumberEventsForTokenAsset(firstTokenId)
      assert.equal(numberOfEvents, 0)
    })

    it('prior to commissioning an asset it should have no existing commissioned assets', async () => {
      await expectRevert(microbatchToken.getCommissionedAsset(firstTokenId), "No assets exist for this token");
    })

    it('can commission an asset on the newly minted token', async () => {
      const receipt = await microbatchToken.commissionAsset(firstTokenId, glnBizLocation1, "harvested", "kg", 500)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: accounts[0], tokenId: new BN(firstTokenId), action: "COMMISSION", bizStep: "harvested", bizLocationId: new BN(glnBizLocation1), inputQuantity: new BN(500), outputQuantity: new BN(500)
      });
    })

    it('newly commissioned asset should have only 1 event', async () => {
      const numberOfEvents = await microbatchToken.getNumberEventsForTokenAsset(firstTokenId)
      assert.equal(numberOfEvents, 1)
    })

    it('cannot commission a second asset on the newly minted token. Only 1 commissioned asset per token', async () => {
      await expectRevert(microbatchToken.commissionAsset(firstTokenId, glnBizLocation1, "harvested", "kg", 500), "This tokenId contains a commissioned asset. Assets can be commissioned once");
    })

    it('can transfer token from one account to another', async () => {
      const receipt = await microbatchToken.safeTransferFrom(accounts[0], accounts[1], 1);
      expectEvent(receipt, 'Transfer', {
        from: accounts[0], to: accounts[1], tokenId: new BN(firstTokenId)
      });
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[1])
      assert.notEqual(owner, accounts[0])
    })

    it('cannot transfer a token the account does not own', async () => {
      await expectRevert(microbatchToken.safeTransferFrom(accounts[0], accounts[1], 1), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot transfer a token unless the transfer caller is the token owner', async () => {
      await expectRevert(microbatchToken.safeTransferFrom(accounts[1], accounts[2], 1), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot approve transferring a token when the account does not own the token', async () => {
      await expectRevert(microbatchToken.approve(accounts[0], 1), "ERC721: approve caller is not owner nor approved for all");
    })

    it('cannot approve the transfer of a token if the token holder and approve account are equal', async () => {
      await expectRevert(microbatchToken.approve(accounts[1], 1), "ERC721: approval to current owner");
    })

    it('can approve another account to transfer a token if account is the token owner', async () => {
      await microbatchToken.approve(accounts[2], 1, { from: accounts[1] });
    })

    it('can transfer token from one account to another using an approved account, i.e. transfer caller is not the token holder', async () => {
      const receipt = await microbatchToken.safeTransferFrom(accounts[1], accounts[2], 1, { from: accounts[2] });
      expectEvent(receipt, 'Transfer', {
        from: accounts[1], to: accounts[2], tokenId: new BN(firstTokenId)
      });
      const owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[2])
      assert.notEqual(owner, accounts[1])
    })

    it('can mint a second token', async () => {
      const receipt = await microbatchToken._mint(accounts[0]);
      expectEvent(receipt, 'Transfer', {
        from: "0x0000000000000000000000000000000000000000", to: accounts[0], tokenId: new BN(secondTokenId)
      });
      const totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 2)
      const owner = await microbatchToken.ownerOf(2)
      assert.equal(owner, accounts[0])
    })

    it('can commission an asset on the second token', async () => {
      const receipt = await microbatchToken.commissionAsset(secondTokenId, glnBizLocation1, "harvested", "kg", 490)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), action: "COMMISSION", bizStep: "harvested", bizLocationId: new BN(glnBizLocation1), inputQuantity: new BN(490), outputQuantity: new BN(490)
      });
    })

    it('each token is associated with a different asset', async () => {
      let asset = await microbatchToken.getCommissionedAsset(firstTokenId)
      assert.equal(asset[0], firstTokenId)
      assert.equal(asset[3], glnBizLocation1)
      assert.equal(asset[4], "harvested")
      assert.equal(asset[6], 500)

      asset = await microbatchToken.getCommissionedAsset(secondTokenId)
      assert.equal(asset[0], secondTokenId)
      assert.equal(asset[3], glnBizLocation1)
      assert.equal(asset[4], "harvested")
      assert.equal(asset[6], 490)
    })

    // A co-op does not produce assets. It takes as input an asset, raw beans, and transforms it to washed and dried beans
    // It can therefore not be used as a bizLocation that creates new assets
    it('cannot associate an asset created in a bizLocation that does not produce assets', async () => {
      await expectRevert(microbatchToken.commissionAsset(secondTokenId, glnBizLocation2, "drying", "kg", 500), "Assets can only be created at facilities that produce/commission raw assets");
    })

    // Transform an asset, i.e. from raw coffee beans to dried beans
    it('can transform an asset', async () => {
      const receipt = await microbatchToken.transformAsset(secondTokenId, glnBizLocation2, "drying", "kg", 490, 440)
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), action: "TRANSFORM", bizStep: "drying", bizLocationId: new BN(glnBizLocation2), inputQuantity: new BN(490), outputQuantity: new BN(440)
      });
    })

    it('can get the event history of an asset', async () => {
      const history = await microbatchToken.getEventHistory(secondTokenId)
      assert.equal(history[0], secondTokenId)
      assert.equal(history[3], glnBizLocation2)
      assert.equal(history[4], "drying")
      assert.equal(history[6], 440)
    })

    it('can observe an asset', async () => {
      let numberEvents = await microbatchToken.getNumberEventsForTokenAsset(secondTokenId)
      assert.equal(numberEvents, 2)
      const receipt = await microbatchToken.observeAsset(secondTokenId, glnBizLocation2, "drying", "kg", 440, "")
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), action: "OBSERVE", bizStep: "drying", bizLocationId: new BN(glnBizLocation2), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await microbatchToken.getNumberEventsForTokenAsset(secondTokenId)
      assert.equal(numberEvents, 3)
    })

    it('can attach sensor data to an asset during an observe event', async () => {
      let numberEvents = await microbatchToken.getNumberEventsForTokenAsset(secondTokenId)
      assert.equal(numberEvents, 3)
      const receipt = await microbatchToken.observeAsset(secondTokenId, glnBizLocation2, "drying", "kg", 440, 
          '{"infoTypeURI": "urn:type:sensor:v2", "sensorType": "temperature", "reading": "25.457", "timestamp": "2020-02-28T14:32:00Z"}');
      expectEvent(receipt, 'TokenAssetEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), action: "OBSERVE", bizStep: "drying", bizLocationId: new BN(glnBizLocation2), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await microbatchToken.getNumberEventsForTokenAsset(secondTokenId)
      assert.equal(numberEvents, 4)
    })
    
    it('can get events recorded against an asset', async () => {
      let assetEvent = await microbatchToken.getAssetEventByIndex(secondTokenId, 1)
      console.log(assetEvent)
      assert.equal(assetEvent[0], secondTokenId)
      assert.equal(assetEvent[2], "")
      assert.equal(assetEvent[4], "harvested")

      let assetEvent = await microbatchToken.getAssetEventByIndex(secondTokenId, 4)
      console.log(assetEvent)
      assert.equal(assetEvent[0], secondTokenId)
      assert.equal(assetEvent[2], "")
      assert.equal(assetEvent[4], "drying")

    })
  })
})
