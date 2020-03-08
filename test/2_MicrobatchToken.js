const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");
const BusinessLocation = artifacts.require("./BusinessLocation.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;
  let businessLocation;
  const firstTokenId = 1;
  const secondTokenId = 2;
  const glnBusinessLocation1 = 123; // as used in BusinessLocation.js, represents the farm
  const glnBusinessLocation2 = 456; // as used in BusinessLocation.js, represents the co-op

  before(async () => {
    microbatchToken = await MicrobatchToken.deployed()
    businessLocation = await BusinessLocation.deployed()
    console.log("ACCOUNTS")
    console.log(accounts)
  })

  describe('deployment-businessLocation', async () => {
    it('businessLocation deploys and initialises successfully', async () => {
      const address = await businessLocation.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can add a new businessLocation', async () => {
      const receipt = await businessLocation.createBusinessLocation(glnBusinessLocation1, "Pacamara Farm", "Organic coffee farm producing pacamara coffee beans", true, true, "1504 Stone Ave, Gold Coast");
      expectEvent(receipt, 'BusinessLocationEvent', {
        gln: new BN(glnBusinessLocation1)
      });
    })

    it('can add a second businessLocation', async () => {
      const receipt = await businessLocation.createBusinessLocation(glnBusinessLocation2, "Charlie Co-op", "Organic co-op for washing and drying coffee beans", true, false, "Unit A, Portland Mountain Road, Gold Coast");
      expectEvent(receipt, 'BusinessLocationEvent', {
        gln: new BN(glnBusinessLocation2)
      });
    })

    it('can query a businessLocation that was previously added', async () => {
      const businessLocationDetail = await businessLocation.get(glnBusinessLocation2);
      assert.equal(businessLocationDetail.businessLocationName, "Charlie Co-op")
      assert.equal(businessLocationDetail.businessLocationStatus, true)
      assert.equal(businessLocationDetail.assetCommission, false)
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
      try {
        await microbatchToken.setBusinessLocationAddress(businessLocation.address);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "BusinessLocation address must contain a valid value when calling setBusinessLocationAddress");
      }
    })

    it('can query a businessLocation added during testing of the Facilties smart contract', async () => {
      const businessLocationDetail = await businessLocation.get(glnBusinessLocation2);
      assert.equal(businessLocationDetail.businessLocationName, "Charlie Co-op")
      assert.equal(businessLocationDetail.businessLocationStatus, true)
      assert.equal(businessLocationDetail.assetCommission, false)
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

    it('can associate an asset with the token', async () => {
      const receipt = await microbatchToken.setTokenAsset(firstTokenId, glnBusinessLocation1, "raw", "harvested", "kg", 500)
      expectEvent(receipt, 'TokenAssetAssociationEvent', {
        tokenOwner: accounts[0], tokenId: new BN(firstTokenId), quantity: new BN(500)
      });
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
      try {
        await microbatchToken.safeTransferFrom(accounts[0], accounts[1], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: transfer caller is not owner nor approved");
      }
    })

    it('cannot transfer a token unless the transfer caller is the token owner', async () => {
      try {
        await microbatchToken.safeTransferFrom(accounts[1], accounts[2], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: transfer caller is not owner nor approved");
      }
    })

    it('cannot approve transferring a token when the account does not own the token', async () => {
      try {
        await microbatchToken.approve(accounts[0], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: approve caller is not owner nor approved for all");
      }
    })

    it('cannot approve the transfer of a token if the token holder and approve account are equal', async () => {
      try {
        await microbatchToken.approve(accounts[1], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: approval to current owner");
      }
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

    it('can associate an asset with the second token', async () => {
      const receipt = await microbatchToken.setTokenAsset(secondTokenId, glnBusinessLocation1,"raw", "harvested", "kg", 490)
      expectEvent(receipt, 'TokenAssetAssociationEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), businessLocationId: new BN(glnBusinessLocation1), bizStep: "harvested", quantity: new BN(490)
      });    
    })

    it('each token is associated with a different asset', async () => {
      let asset = await microbatchToken.getTokenAsset(firstTokenId)
      assert.equal(asset[0], firstTokenId)
      assert.equal(asset[1], glnBusinessLocation1)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 500)

      asset = await microbatchToken.getTokenAsset(secondTokenId)
      assert.equal(asset[0], secondTokenId)
      assert.equal(asset[1], glnBusinessLocation1)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 490)
    })

    // A co-op does not produce assets. It takes as input an asset, raw beans, and transforms it to washed and dried beans
    // It can therefore not be used as a businessLocation that creates new assets
    it('cannot associate an asset created in a businessLocation that does not produce assets', async () => {
      try {
        await microbatchToken.setTokenAsset(secondTokenId, glnBusinessLocation2, "raw", "drying", "kg", 500)
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Assets can only be created at facilities that produce/commission raw assets");
      }
    })

    // Transform an asset, i.e. from raw coffee beans to dried beans
    it('cannot transform an asset', async () => {
      try {
        await microbatchToken.transformAsset(secondTokenId, glnBusinessLocation2, "raw", "drying", "kg", 450)
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Assets can only be created at facilities that produce/commission raw assets");
      }
      expectEvent(receipt, 'TokenAssetAssociationEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), businessLocationId: new BN(glnBusinessLocation1), bizStep: "harvested", quantity: new BN(490)
      });    
    })

    // Transform an asset, i.e. from raw coffee beans to dried beans
    it('can transform an asset', async () => {
      try {
        await microbatchToken.transformAsset(secondTokenId, glnBusinessLocation2, "raw", "drying", "kg", 450)
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Assets can only be created at facilities that produce/commission raw assets");
      }
      expectEvent(receipt, 'TokenAssetAssociationEvent', {
        tokenOwner: accounts[0], tokenId: new BN(secondTokenId), businessLocationId: new BN(glnBusinessLocation1), bizStep: "harvested", quantity: new BN(490)
      });    
    })

    it('can get the transform history of an asset', async () => {
        const history = await microbatchToken.getTransformHistory(secondTokenId)
        assert.equal(history[0], secondTokenId)
        assert.equal(history[1], glnBusinessLocation1)
        assert.equal(history[3], "harvested")
        assert.equal(history[4], 490)
      })
  })
})