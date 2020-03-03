const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;
  let tokenId;

  before(async () => {
    microbatchToken = await MicrobatchToken.deployed()
    console.log(accounts)
  })

  describe('deployment', async () => {
    it('deploys and initialises successfully', async () => {
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
      assert.equal(event.returnValues.tokenId, 1)
      tokenId = event.returnValues.tokenId
    })

    it('can associate an asset with the token', async () => {
      await microbatchToken.setTokenAsset(tokenId, "farmer facility","raw", "harvested", "kg", "500")
      events = await microbatchToken.getPastEvents('TokenAssetEvent', { toBlock: 'latest' })
      const event = events[0]
      console.log(event)
      assert.equal(event.returnValues.tokenOwner, accounts[0])
      assert.equal(event.returnValues.tokenId, tokenId)
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
      assert.equal(event.returnValues.tokenId, 1)
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
      assert.equal(event.returnValues.tokenId, 1)
    })
  })
})