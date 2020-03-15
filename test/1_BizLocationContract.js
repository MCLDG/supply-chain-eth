const BizLocationContract = artifacts.require("./BizLocationContract.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

contract('BizLocationContract', (accounts) => {
  let bizLocation;
  let glnBizLocation1 = 123;
  let glnBizLocation2 = 456;

  before(async () => {
    bizLocation = await BizLocationContract.deployed()
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
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
      let bizLocationDetail = await bizLocation.get(glnBizLocation2);
      assert.equal(bizLocationDetail.bizLocationName, "Charlie Co-op")
      assert.equal(bizLocationDetail.bizLocationActive, true)
      assert.equal(bizLocationDetail.tradeItemCommission, false)
    })
  })
})