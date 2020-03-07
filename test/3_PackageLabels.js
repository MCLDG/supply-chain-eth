const PackageLabels = artifacts.require("./PackageLabels.sol");
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

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
      const receipt = await packageLabels.registerPackageLabel("batch1", 1);
      expectEvent(receipt, 'PackageLabelBatchEvent', {
        batchId: "batch1", batchSize: new BN(1)
      });
      let batchSize = await packageLabels.getPackageLabelBatchSize("batch1");
      assert.equal(batchSize, 1);
    })

    it('can get the batch size of a registered batch of packaging labels', async () => {
      let batchSize = await packageLabels.getPackageLabelBatchSize("batch1");
      assert.equal(batchSize, 1);
    })

    it("should throw an exception if the label batch size is < 1", async () => {
      await expectRevert(packageLabels.registerPackageLabel("batch1", 0), "batch size must be > 0 when registering a batch of labels");
    });

    it('can update the location where the label certificate is stored', async () => {
      await packageLabels.uploadPackageLabelCertificateIPFS("batch1", "QmfXFK9G4o4ZCFfL3NZM2NCuyPmzHPAnbvbucHt72yCgJr");
      let labelCertificateHashIPFS = await packageLabels.getPackageLabelCertificateHashIPFS("batch1");
      assert.equal(labelCertificateHashIPFS, "QmfXFK9G4o4ZCFfL3NZM2NCuyPmzHPAnbvbucHt72yCgJr");
    })

    it('cannot update the location where the label certificate is stored to an empty string', async () => {
      await expectRevert(packageLabels.uploadPackageLabelCertificateIPFS("batch1", ""), "the labels certificate must contain a string value representing an IPFS hash");
    })

    it('cannot update the location where the label certificate is stored for a non-existant batch', async () => {
      await expectRevert(packageLabels.uploadPackageLabelCertificateIPFS("batch2", ""), "batch for batchId must exist, i.e. must have been previously registered");
    })
  })
})