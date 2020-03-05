const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");
const Facility = artifacts.require("./Facility.sol");

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;
  let facility;
  let firstTokenId = 1;
  let secondTokenId = 2;
  let glnFacility1 = 123; // as used in Facility.js, represents the farm
  let glnFacility2 = 456; // as used in Facility.js, represents the co-op

  before(async () => {
    microbatchToken = await MicrobatchToken.deployed()
    facility = await Facility.deployed()
    console.log("ACCOUNTS")
    console.log(accounts)
  })

  describe('deployment-facility', async () => {
    it('facility deploys and initialises successfully', async () => {
      const address = await facility.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can add a new facility', async () => {
      const result = await facility.createFacility(glnFacility1, "Pacamara Farm", "Organic coffee farm producing pacamara coffee beans", "active", true, "1504 Stone Ave, Gold Coast");
      events = await facility.getPastEvents('FacilityEvent', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.gln, glnFacility1)
    })

    it('can add a second facility', async () => {
      const result = await facility.createFacility(glnFacility2, "Charlie Co-op", "Organic co-op for washing and drying coffee beans", "active", false, "Unit A, Portland Mountain Road, Gold Coast");
      events = await facility.getPastEvents('FacilityEvent', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.gln, glnFacility2)
    })

    it('can query a facility that was previously added', async () => {
      let facilityDetail = await facility.get(glnFacility2);
      assert.equal(facilityDetail.facilityName, "Charlie Co-op")
      assert.equal(facilityDetail.facilityStatus, "active")
      assert.equal(facilityDetail.assetCommission, false)
    })
  })

  describe('deployment-microbatchToken', async () => {
    it('microbatchToken deploys and initialises successfully', async () => {
      const address = await microbatchToken.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
      let totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 0)
      let name = await microbatchToken.name()
      let symbol = await microbatchToken.symbol()
      assert.equal(name, "MICROBATCH")
      assert.equal(symbol, "MBAT")
    })

    it('can set the address of the Facilties smart contract', async () => {
      try {
        await microbatchToken.setFacilityAddress(facility.address);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Facility address must contain a valid value when calling setFacilityAddress");
      }
    })

    it('can query a facility added during testing of the Facilties smart contract', async () => {
      let facilityDetail = await facility.get(glnFacility2);
      assert.equal(facilityDetail.facilityName, "Charlie Co-op")
      assert.equal(facilityDetail.facilityStatus, "active")
      assert.equal(facilityDetail.assetCommission, false)
    })

    it('can mint a new token', async () => {
      await microbatchToken._mint(accounts[0]);
      let totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 1)
      let owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[0])
      events = await microbatchToken.getPastEvents('Transfer', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.from, "0x0000000000000000000000000000000000000000")
      assert.equal(event.returnValues.to, accounts[0])
      assert.equal(event.returnValues.tokenId, firstTokenId)
    })

    it('can associate an asset with the token', async () => {
      await microbatchToken.setTokenAsset(firstTokenId, glnFacility1, "raw", "harvested", "kg", 500)
      events = await microbatchToken.getPastEvents('TokenAssetEvent', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.tokenOwner, accounts[0])
      assert.equal(event.returnValues.tokenId, firstTokenId)
      assert.equal(event.returnValues.assetQuantity, 500)
    })

    it('can transfer token from one account to another', async () => {
      await microbatchToken.safeTransferFrom(accounts[0], accounts[1], 1);
      let owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[1])
      assert.notEqual(owner, accounts[0])
      events = await microbatchToken.getPastEvents('Transfer', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.from, accounts[0])
      assert.equal(event.returnValues.to, accounts[1])
      assert.equal(event.returnValues.tokenId, firstTokenId)
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
      await microbatchToken.safeTransferFrom(accounts[1], accounts[2], 1, { from: accounts[2] });
      let owner = await microbatchToken.ownerOf(1)
      assert.equal(owner, accounts[2])
      assert.notEqual(owner, accounts[1])
      events = await microbatchToken.getPastEvents('Transfer', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.from, accounts[1])
      assert.equal(event.returnValues.to, accounts[2])
      assert.equal(event.returnValues.tokenId, firstTokenId)
    })

    it('can mint a second token', async () => {
      await microbatchToken._mint(accounts[0]);
      let totalSupply = await microbatchToken.totalSupply()
      assert.equal(totalSupply, 2)
      let owner = await microbatchToken.ownerOf(2)
      assert.equal(owner, accounts[0])
      events = await microbatchToken.getPastEvents('Transfer', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.from, "0x0000000000000000000000000000000000000000")
      assert.equal(event.returnValues.to, accounts[0])
      assert.equal(event.returnValues.tokenId, secondTokenId)
    })

    it('can associate an asset with the second token', async () => {
      await microbatchToken.setTokenAsset(secondTokenId, glnFacility1,"raw", "harvested", "kg", 490)
      events = await microbatchToken.getPastEvents('TokenAssetEvent', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.tokenOwner, accounts[0])
      assert.equal(event.returnValues.tokenId, secondTokenId)
      assert.equal(event.returnValues.facilityId, glnFacility1)
      assert.equal(event.returnValues.assetProcess, "harvested")
      assert.equal(event.returnValues.assetQuantity, 490)
    })

    it('each token is associated with a different asset', async () => {
      let asset = await microbatchToken.getTokenAsset(firstTokenId)
      assert.equal(asset[0], firstTokenId)
      assert.equal(asset[1], glnFacility1)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 500)

      asset = await microbatchToken.getTokenAsset(secondTokenId)
      assert.equal(asset[0], secondTokenId)
      assert.equal(asset[1], glnFacility1)
      assert.equal(asset[3], "harvested")
      assert.equal(asset[5], 490)
    })

    // A co-op does not produce assets. It takes as input an asset, raw beans, and transforms it to washed and dried beans
    // It can therefore not be used as a facility that creates new assets
    it('cannot associate an asset created in a facility that does not produce assets', async () => {
      try {
        await microbatchToken.setTokenAsset(secondTokenId, glnFacility2, "raw", "drying", "kg", 500)
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Assets can only be created at facilities that produce/commission raw assets");
      }
    })

    // Transform an asset, i.e. from raw coffee beans to dried beans
    it('can transform an asset', async () => {
      try {
        await microbatchToken.transformTokenAsset(secondTokenId, glnFacility2, "raw", "drying", "kg", 450)
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "Assets can only be created at facilities that produce/commission raw assets");
      }
    })

    it('can get the transform history of an asset', async () => {
        let history = await microbatchToken.getTransformHistory(secondTokenId)
        assert.equal(history[0], secondTokenId)
        assert.equal(history[1], glnFacility1)
        assert.equal(history[3], "harvested")
        assert.equal(history[4], 490)
      })
  })
})