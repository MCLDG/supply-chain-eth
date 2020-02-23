const PackageLabels = artifacts.require("./PackageLabels.sol");

contract('PackageLabels', (accounts) => {
  let packageLabels;

  before(async () => {
    packageLabels = await PackageLabels.deployed()
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
      const address = await packageLabels.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('can register a batch of packaging labels', async () => {
      const result = await packageLabels.registerPackageLabel("batch1", 1, "url://");
      let batchSize = await packageLabels.getPackageLabelBatchSize("batch1");
      assert.equal(batchSize, 1);
      const event = result.logs[0].args
      assert.equal(event.batchId, "batch1")
      assert.equal(event.batchSize.toNumber(), 1)
      assert.equal(event.labelCertificateLocation, "url://")

    })

    it('can get the batch size of a registered batch of packaging labels', async () => {
      let batchSize = await packageLabels.getPackageLabelBatchSize("batch1");
      assert.equal(batchSize, 1);
    })

    it("should throw an exception if the label batch size is < 1", async () => {
      try {
        await packageLabels.registerPackageLabel("batch1", 0, "url://");
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "batch size must be > 0 when registering a batch of labels");
      }
    });

    it('can update the location where the label certificate is stored', async () => {
      await packageLabels.uploadPackageLabelCertificate("batch1", "url://labelcertificate");
      let labelCertificateLocation = await packageLabels.getPackageLabelCertificateLocation("batch1");
      assert.equal(labelCertificateLocation, "url://labelcertificate");
    })

    it('cannot update the location where the label certificate is stored to an empty string', async () => {
      try {
        await packageLabels.uploadPackageLabelCertificate("batch1", "");
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "the storage location for the labels certificate must contain a string value");
      }
    })

    it('cannot update the location where the label certificate is stored for a non-existant batch', async () => {
      try {
        await packageLabels.uploadPackageLabelCertificate("batch2", "");
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "batch for batchId must exist, i.e. must have been previously registered");
      }
    })
  })
})