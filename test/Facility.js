const Facility = artifacts.require("./Facility.sol");

contract('Facility', (accounts) => {
  let facilities;
  let gln = 1234567890123;

  before(async () => {
    facilities = await Facility.deployed()
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
      const address = await facilities.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can add a new facility', async () => {
      const result = await facilities.createFacility(gln, "Pacamara Farm", "Organic coffee farm producing pacamara coffee beans", "active", "1504 Stone Ave, Gold Coast");
      events = await facilities.getPastEvents('FacilityEvent', { toBlock: 'latest' })
      const event = events[0]
      assert.equal(event.returnValues.gln, gln)
    })
  })
})