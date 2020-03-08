const BusinessLocation = artifacts.require("./BusinessLocation.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('BusinessLocation', (accounts) => {
  let businessLocation;
  let glnBusinessLocation1 = 123;
  let glnBusinessLocation2 = 456;

  before(async () => {
    businessLocation = await BusinessLocation.deployed()
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
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
      let businessLocationDetail = await businessLocation.get(glnBusinessLocation2);
      assert.equal(businessLocationDetail.businessLocationName, "Charlie Co-op")
      assert.equal(businessLocationDetail.businessLocationActive, true)
      assert.equal(businessLocationDetail.assetCommission, false)
    })
  })
})