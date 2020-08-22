const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

// ABI
const IndexInterfaceABI = require("./abi/IndexInterface.json");
const AccountInterfaceABI = require("./abi/AccountInterface.json");
const ERC20ABI = require("./abi/ERC20.json");

// Contracts
const MockContract = artifacts.require("MockContract")
const ManagerContract = artifacts.require("Manager")

contract("Manager", accounts => {
  const [sender, receiver] =  accounts;
  let indexContract, accountContract, mock, manager;

  before(async function(){
    mock = await MockContract.new()
    indexContract = new web3.eth.Contract(IndexInterfaceABI, mock.address);
    accountContract = new web3.eth.Contract(AccountInterfaceABI, mock.address);
    manager = await ManagerContract.new(mock.address)
    const master = await indexContract.methods.master().encodeABI()
    mock.givenMethodReturnAddress(master, sender)
  })

  it("Should be able to enable Manager", async function() {
    const tx = await manager.enableManager(receiver);
    const isManager = await manager.managers(receiver);
    expect(isManager).to.equal(true)
    expectEvent(tx, "LogEnableManager");
  });

  it("Should be able to disable Manager", async function() {
    const tx = await manager.disableManager(receiver);
    const isManager = await manager.managers(receiver);
    expect(isManager).to.equal(false)
    expectEvent(tx, "LogDisableManager");
  });

  it("Should be able to enable connector", async function() {
    const tx = await manager.enableConnector(receiver);
    const isConnector = await manager.connectors(receiver);
    expect(isConnector).to.equal(true)
    expectEvent(tx, "LogEnableConnector");
  });

  it("Should be able to disable connector", async function() {
    const tx = await manager.disableConnector(receiver);
    const isConnector = await manager.connectors(receiver);
    expect(isConnector).to.equal(false)
    expectEvent(tx, "LogDisableConnector");
  });

  it('should be able to call spell', async function() {
    const tokenContract = new web3.eth.Contract(ERC20ABI, mock.address);
    const approve = tokenContract.methods.approve(receiver, "1000").encodeABI()
    const tx = await manager.spell(mock.address, approve);
    expectEvent(tx, "LogSpell");
  });

  it('should be able to cast spells', async function() {
    await manager.enableManager(sender);
    const tokenContract = new web3.eth.Contract(ERC20ABI, mock.address);
    const approve = tokenContract.methods.approve(receiver, "1000").encodeABI()
    const transfer = tokenContract.methods.transfer(receiver, "1000").encodeABI()
    const tx = await manager.cast([mock.address, mock.address], [approve, transfer], mock.address);
    expectEvent(tx, "LogCast");
  });
});
