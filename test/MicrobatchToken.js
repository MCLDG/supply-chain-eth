const MicrobatchToken = artifacts.require("./MicrobatchToken.sol");

contract('MicrobatchToken', (accounts) => {
  let microbatchToken;

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

    it('account cannot transfer a token it does not own', async () => {
      try {
        await microbatchToken.safeTransferFrom(accounts[0], accounts[1], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: transfer caller is not owner nor approved");
      }
    })

    it('account that owns the token cannot transfer a token unless it is approved', async () => {
      try {
        await microbatchToken.safeTransferFrom(accounts[1], accounts[0], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: transfer caller is not owner nor approved");
      }
    })
    it('account cannot approve transferring a token it does not own', async () => {
      try {
        await microbatchToken.approve(accounts[0], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: approve caller is not owner nor approved for all");
      }
    })

    it('account cannot approve transferring a token it does not own', async () => {
      try {
        await microbatchToken.approve(accounts[1], 1);
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: approval to current owner");
      }
    })

    it('can approve token approval from 0x0 account', async () => {
      try {
        let address = await microbatchToken.getApproved(1);
        let owner = await microbatchToken.ownerOf(1);
        console.log("approved address: " + address);
        console.log("owner address: " + owner);
        await microbatchToken.approve(accounts[1], 1).send({
          from: accounts[1]
        });;
      } catch (error) {
        assert.throws(() => { throw new Error(error) }, Error, "ERC721: approval to current owner");
      }
    })
    // it('account can approve transferring a token it does own', async () => {
    //   try {
    //     let address = await microbatchToken.getApproved(1);
    //     console.log("approved address: " + address);
    //     await microbatchToken.approve(accounts[0], 1).send({
    //       from: accounts[1]
    //     });;
    //     assert(true);
    //   } catch (error) {
    //     assert(false);
    //   }
    // })
    // it('account can transfer a token it does not own if it receives approval', async () => {
    //   try {
    //     await microbatchToken.approve(accounts[0], 1).send({
    //       from: accounts[1]
    //     });;
    //     await microbatchToken.safeTransferFrom(accounts[1], accounts[0], 1);
    //     assert(true);
    //   } catch (error) {
    //     assert(false);
    //   }
    // })
  })
})