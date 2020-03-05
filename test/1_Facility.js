const Facility = artifacts.require("./Facility.sol");

contract('Facility', (accounts) => {
  let facility;
  let glnFacility1 = 123;
  let glnFacility2 = 456;

  before(async () => {
    facility = await Facility.deployed()
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
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
})