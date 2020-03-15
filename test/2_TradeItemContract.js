const TradeItemContract = artifacts.require("./TradeItemContract.sol");
const BizLocationContract = artifacts.require("./BizLocationContract.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

contract('TradeItemContract', (accounts) => {
  let tradeItemContract;
  let bizLocation;
  const harvestedCrop1GTIN = 1;
  const harvestedCrop2GTIN = 2;
  const packagingGTIN = 3;
  const labellingGTIN = 4;
  const glnBizLocationFarm1 = 123; // as used in BizLocationContract.js, represents the farm
  const glnBizLocationFarm2 = 123; // as used in BizLocationContract.js, represents the farm
  const glnBizLocationCoop = 456; // as used in BizLocationContract.js, represents the co-op
  const glnBizLocationPackaging = 789; // as used in BizLocationContract.js, represents the Packaging manufacturer
  const glnBizLocationLabel = 012; // as used in BizLocationContract.js, represents the Label manufacturer
  const farmer1Account = accounts[0];
  const farmer2Account = accounts[1];
  const coopAccount = accounts[2];
  const shipperAccount = accounts[4];
  const packagingAccount = accounts[5];
  const labellerAccount = accounts[6];
  const roasterAccount = accounts[7];

  before(async () => {
    tradeItemContract = await TradeItemContract.deployed()
    bizLocation = await BizLocationContract.deployed()
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
      assert.equal(bizLocationDetail.tradeItemCommission, false)
    })
  })

  describe('deployment-tradeItemContract', async () => {

    it('tradeItemContract deploys and initialises successfully', async () => {
      const address = await tradeItemContract.address
      assert.notEqual(address, ZERO_ADDRESS)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
      const totalSupply = await tradeItemContract.totalSupply()
      assert.equal(totalSupply, 0)
      const name = await tradeItemContract.name()
      const symbol = await tradeItemContract.symbol()
      assert.equal(name, "TRADEITEM")
      assert.equal(symbol, "TRDI")
    })

    it('can set the address of the Facilties smart contract', async () => {
      tradeItemContract.setBizLocationAddress(bizLocation.address);
    })

    it('can query a bizLocation added during testing of the Facilties smart contract', async () => {
      const bizLocationDetail = await bizLocation.get(glnBizLocationCoop);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.tradeItemCommission, false)
    })

    it('can mint a new token', async () => {
      const receipt = await tradeItemContract.mint(farmer1Account, harvestedCrop1GTIN);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: farmer1Account, tokenId: new BN(harvestedCrop1GTIN)
      });
      const totalSupply = await tradeItemContract.totalSupply()
      assert.equal(totalSupply, 1)
      const owner = await tradeItemContract.ownerOf(1)
      assert.equal(owner, farmer1Account)
    })

    it('prior to commissioning a tradeItem it should have no events', async () => {
      const numberOfEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop1GTIN)
      assert.equal(numberOfEvents, 0)
    })

    it('prior to commissioning a tradeItem it should have no existing commissioned tradeItems', async () => {
      await expectRevert(tradeItemContract.getCommissionedTradeItem(harvestedCrop1GTIN), "No tradeItems exist for this token");
    })

    it('can commission a tradeItem on the newly minted token', async () => {
      const receipt = await tradeItemContract.commissionTradeItem(harvestedCrop1GTIN, glnBizLocationFarm1, "harvested", "active", "kg", 500)
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: farmer1Account, GTIN: new BN(harvestedCrop1GTIN), action: "COMMISSION", bizStep: "harvested", bizLocationGLN: new BN(glnBizLocationFarm1), inputQuantity: new BN(500), outputQuantity: new BN(500)
      });
    })

    it('newly commissioned tradeItem should have only 1 event', async () => {
      const numberOfEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop1GTIN)
      assert.equal(numberOfEvents, 1)
    })

    it('cannot commission a second tradeItem on the newly minted token. Only 1 commissioned tradeItem per token', async () => {
      await expectRevert(tradeItemContract.commissionTradeItem(harvestedCrop1GTIN, glnBizLocationFarm1, "harvested", "active", "kg", 500), "A commissioned tradeItem can only be commissioned once");
    })

    it('can transfer token from one account to another', async () => {
      const receipt = await tradeItemContract.safeTransferFrom(farmer1Account, coopAccount, harvestedCrop1GTIN);
      expectEvent(receipt, 'Transfer', {
        from: farmer1Account, to: coopAccount, tokenId: new BN(harvestedCrop1GTIN)
      });
      const owner = await tradeItemContract.ownerOf(1)
      assert.equal(owner, coopAccount)
      assert.notEqual(owner, farmer1Account)
    })

    it('cannot transfer a token the account does not own', async () => {
      await expectRevert(tradeItemContract.safeTransferFrom(farmer1Account, coopAccount, harvestedCrop1GTIN), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot transfer a token unless the transfer caller is the token owner (differs from the token holder)', async () => {
      await expectRevert(tradeItemContract.safeTransferFrom(coopAccount, shipperAccount, harvestedCrop1GTIN), "ERC721: transfer caller is not owner nor approved");
    })

    it('cannot approve transferring a token when the account does not own the token', async () => {
      await expectRevert(tradeItemContract.approve(shipperAccount, harvestedCrop1GTIN), "ERC721: approve caller is not owner nor approved for all");
    })

    it('cannot approve the transfer of a token if the token holder and approve account are equal', async () => {
      await expectRevert(tradeItemContract.approve(coopAccount, harvestedCrop1GTIN), "ERC721: approval to current owner");
    })

    it('can approve another account to transfer a token if account is the token owner', async () => {
      await tradeItemContract.approve(shipperAccount, harvestedCrop1GTIN, { from: coopAccount });
    })

    it('can transfer token from one account to another using an approved account, i.e. transfer caller is not the token holder', async () => {
      const receipt = await tradeItemContract.safeTransferFrom(coopAccount, shipperAccount, harvestedCrop1GTIN, { from: shipperAccount });
      expectEvent(receipt, 'Transfer', {
        from: coopAccount, to: shipperAccount, tokenId: new BN(harvestedCrop1GTIN)
      });
      const owner = await tradeItemContract.ownerOf(1)
      assert.equal(owner, shipperAccount)
      assert.notEqual(owner, coopAccount)
    })

    it('can mint a second token', async () => {
      const receipt = await tradeItemContract.mint(farmer2Account, harvestedCrop2GTIN);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: farmer2Account, tokenId: new BN(harvestedCrop2GTIN)
      });
      const totalSupply = await tradeItemContract.totalSupply()
      assert.equal(totalSupply, 2)
      const owner = await tradeItemContract.ownerOf(2)
      assert.equal(owner, farmer2Account)
    })

    it('can commission a tradeItem on the second token', async () => {
      const receipt = await tradeItemContract.commissionTradeItem(harvestedCrop2GTIN, glnBizLocationFarm2, "harvested", "active", "kg", 490)
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: farmer2Account, GTIN: new BN(harvestedCrop2GTIN), action: "COMMISSION", bizStep: "harvested", bizLocationGLN: new BN(glnBizLocationFarm2), inputQuantity: new BN(490), outputQuantity: new BN(490)
      });
    })

    it('each token is associated with a different tradeItem', async () => {
      let tradeItem = await tradeItemContract.getCommissionedTradeItem(harvestedCrop1GTIN)
      assert.equal(tradeItem[0], harvestedCrop1GTIN)
      assert.equal(tradeItem[2], glnBizLocationFarm1)
      assert.equal(tradeItem[3], "harvested")
      assert.equal(tradeItem[5], 500)

      tradeItem = await tradeItemContract.getCommissionedTradeItem(harvestedCrop2GTIN)
      assert.equal(tradeItem[0], harvestedCrop2GTIN)
      assert.equal(tradeItem[2], glnBizLocationFarm2)
      assert.equal(tradeItem[3], "harvested")
      assert.equal(tradeItem[5], 490)
    })

    // A co-op does not produce tradeItems. It takes as input a tradeItem, raw beans, and transforms it to washed and dried beans
    // It can therefore not be used as a bizLocation that creates new tradeItems
    it('cannot associate a tradeItem created in a bizLocation that does not produce tradeItems', async () => {
      await expectRevert(tradeItemContract.commissionTradeItem(harvestedCrop2GTIN, glnBizLocationCoop, "drying", "in-progress", "kg", 500), "tradeItems can only be created at facilities that produce raw tradeItems");
    })

    // Transform a tradeItem, i.e. from raw coffee beans to dried beans
    it('can transform a tradeItem', async () => {
      const receipt = await tradeItemContract.transformTradeItem(harvestedCrop2GTIN, glnBizLocationCoop, "drying", "in-progress", "kg", 490, 440)
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: farmer2Account, GTIN: new BN(harvestedCrop2GTIN), action: "TRANSFORM", bizStep: "drying", bizLocationGLN: new BN(glnBizLocationCoop), inputQuantity: new BN(490), outputQuantity: new BN(440)
      });
    })

    it('can get the event history of a tradeItem', async () => {
      const history = await tradeItemContract.getEventHistory(harvestedCrop2GTIN)
      assert.equal(history[0], harvestedCrop2GTIN)
      assert.equal(history[2], glnBizLocationCoop)
      assert.equal(history[3], "drying")
      assert.equal(history[5], 440)
    })

    it('can observe a tradeItem', async () => {
      let numberEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop2GTIN)
      assert.equal(numberEvents, 2)
      const receipt = await tradeItemContract.observeTradeItem(harvestedCrop2GTIN, glnBizLocationCoop, "drying", "in-progress", "kg", 440, "")
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: farmer2Account, GTIN: new BN(harvestedCrop2GTIN), action: "OBSERVE", bizStep: "drying", bizLocationGLN: new BN(glnBizLocationCoop), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop2GTIN)
      assert.equal(numberEvents, 3)
    })

    it('can attach sensor data to a tradeItem during an observe event', async () => {
      let numberEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop2GTIN)
      assert.equal(numberEvents, 3)
      const receipt = await tradeItemContract.observeTradeItem(harvestedCrop2GTIN, glnBizLocationCoop, "drying", "in-progress", "kg", 440,
        '{"infoTypeURI": "urn:type:sensor:v2", "sensorType": "temperature", "reading": "25.457", "timestamp": "2020-02-28T14:32:00Z"}');
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: farmer2Account, GTIN: new BN(harvestedCrop2GTIN), action: "OBSERVE", bizStep: "drying", bizLocationGLN: new BN(glnBizLocationCoop), inputQuantity: new BN(440), outputQuantity: new BN(440)
      });
      numberEvents = await tradeItemContract.getNumberEventsForTradeItem(harvestedCrop2GTIN)
      assert.equal(numberEvents, 4)
    })

    it('can get events recorded against a tradeItem', async () => {
      let tradeItemEvent = await tradeItemContract.getTradeItemEventByIndex(harvestedCrop2GTIN, 0)
      assert.equal(tradeItemEvent[0], harvestedCrop2GTIN)
      assert.equal(tradeItemEvent[1], "")
      assert.equal(tradeItemEvent[3], "harvested")

      tradeItemEvent = await tradeItemContract.getTradeItemEventByIndex(harvestedCrop2GTIN, 3)
      assert.equal(tradeItemEvent[0], harvestedCrop2GTIN)
      assert.equal(tradeItemEvent[1], '{"infoTypeURI": "urn:type:sensor:v2", "sensorType": "temperature", "reading": "25.457", "timestamp": "2020-02-28T14:32:00Z"}')
      assert.equal(tradeItemEvent[3], "drying")
    })

    // Can support packaging and labels as a tradeItem
    it('can mint a token to hold a batch of Packaging tradeItems', async () => {
      const receipt = await tradeItemContract.mint(packagingAccount, packagingGTIN);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: packagingAccount, tokenId: new BN(packagingGTIN)
      });
      const totalSupply = await tradeItemContract.totalSupply()
      assert.equal(totalSupply, 3)
      const owner = await tradeItemContract.ownerOf(packagingGTIN)
      assert.equal(owner, packagingAccount)
    })

    // The tradeItem below is created with an empty UOM. According to EPCIS, if UOM is empty, the quantity field contains a count of items (in this case, 1,000 packages)
    it('can commission a tradeItem representing the batch of packaging', async () => {
      const receipt = await tradeItemContract.commissionTradeItem(packagingGTIN, glnBizLocationPackaging, "batch of packaging", "active", "", 1000)
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: packagingAccount, GTIN: new BN(packagingGTIN), action: "COMMISSION", bizStep: "batch of packaging", bizLocationGLN: new BN(glnBizLocationPackaging), inputQuantity: new BN(1000), outputQuantity: new BN(1000)
      });
    })

    it('can mint a token to hold a batch of Label tradeItems', async () => {
      const receipt = await tradeItemContract.mint(labellerAccount, labellingGTIN);
      expectEvent(receipt, 'Transfer', {
        from: ZERO_ADDRESS, to: labellerAccount, tokenId: new BN(labellingGTIN)
      });
      const totalSupply = await tradeItemContract.totalSupply()
      assert.equal(totalSupply, 4)
      const owner = await tradeItemContract.ownerOf(labellingGTIN)
      assert.equal(owner, labellerAccount)
    })

    // The tradeItem below is created with an empty UOM. According to EPCIS, if UOM is empty, the quantity field contains a count of items (in this case, 1,000 packages)
    it('can commission a tradeItem representing the batch of labels', async () => {
      const receipt = await tradeItemContract.commissionTradeItem(labellingGTIN, glnBizLocationLabel, "batch of labels", "active", "", 2000)
      expectEvent(receipt, 'TradeItemEmitEvent', {
        tokenOwner: labellerAccount, GTIN: new BN(labellingGTIN), action: "COMMISSION", bizStep: "batch of labels", bizLocationGLN: new BN(glnBizLocationLabel), inputQuantity: new BN(2000), outputQuantity: new BN(2000)
      });
    })

    // Test the entire process, from commissioning a tradeItem, progressing it through transforms and observes, 
    // and finally aggregating it into a packaged product
  })

})
