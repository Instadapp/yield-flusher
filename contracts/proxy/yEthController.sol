pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

contract Controller {

    event LogChangeFee(uint256 _fee);
    event LogChangeMaxGasFee(uint256 _fee);
    event LogChangeFeeCollector(address _feeCollector);
    event LogChangeGasFeeCollector(address _feeCollector);

    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    uint256 public fee;
    uint256 public maxGasFee;
    address public feeCollector;
    address public gasFeeCollector;

    mapping (address => uint) public balanceOf;

    modifier isChief {
        require(IndexInterface(instaIndex).master() == msg.sender, "not-Master");
        _;
    }

    function changeFee(uint256 _fee) external isChief {
        require(_fee <= 2 * 10 ** 17, "Fee is more than 0.2%");
        fee = uint64(_fee);
        emit LogChangeFee(_fee);
    }

    function changeFeeCollector(address _feeCollector) external isChief {
        require(feeCollector != _feeCollector, "Same-feeCollector");
        require(_feeCollector != address(0), "feeCollector-is-address(0)");
        feeCollector = _feeCollector;
        emit LogChangeFeeCollector(_feeCollector);
    }

    function changeMaxGasFee(uint256 _maxGasFee) external isChief {
        require(_maxGasFee <= 5 * 10 ** 17, "gas fee more than 0.5 ETH");
        maxGasFee = uint64(_maxGasFee);
        emit LogChangeMaxGasFee(_maxGasFee);
    }

    function changeGasFeeCollector(address _gasFeeCollector) external isChief {
        require(gasFeeCollector != _gasFeeCollector, "Same-gas-fee-collector");
        require(_gasFeeCollector != address(0), "gasFeeCollector-is-address(0)");
        gasFeeCollector = _gasFeeCollector;
        emit LogChangeGasFeeCollector(_gasFeeCollector);
    }

    // Public functions

    function depositAmt(uint amt) external {
        balanceOf[msg.sender] += amt;
        // TODO - event
    }

    function withdrawAmt(uint amt) external {
        uint _depositedAmt = balanceOf[msg.sender];
        balanceOf[msg.sender] -= amt > _depositedAmt ? _depositedAmt : amt;
        // TODO - event
    }
}

contract yEthController is Controller {
    constructor () public {
        fee = 1 * 10 ** 17;  // 10%
        maxGasFee = 2 * 10 ** 17;  // max 0.2 ETH
        feeCollector = IndexInterface(instaIndex).master(); // TODO - Change
        gasFeeCollector = IndexInterface(instaIndex).master(); // TODO - Change

    }
}
