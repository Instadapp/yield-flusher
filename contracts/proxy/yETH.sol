pragma solidity ^0.6.0;

interface yEthInterface {
    function depositETH() external payable;
    function withdrawETH(uint) external;
    function getPricePerFullShare() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}

interface ControllerInterface {
    function deposit(uint) external;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function fee() external view returns (uint);
    function feeCollector() external view returns (address);
    function gasFeeCollector() external view returns (address);
    function maxGasFeeAmount() external view returns (uint);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return ethereum address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH Address
    }

    /**
     * @dev Return controller address
     */
    function getControllerAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // TODO - change.
    }
}


contract yEthHelpers is Helpers {
    /**
     * @dev Return yETH Address
     */
    function getYEthAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    function _withdrawAndCalculateFee(
        yEthInterface yETH,
        ControllerInterface controller,
        uint withdrawAmt
    ) internal returns (uint withdrewAmt, uint withdrawalFee, uint amtWithoutProfit, uint feeAmt) {
        uint sharePrice = yETH.getPricePerFullShare();
        uint totalShares = yETH.balanceOf(address(this));
        uint shareAmt = wdiv(withdrawAmt, sharePrice); 
        shareAmt = shareAmt >= totalShares ?  totalShares : shareAmt;
        uint initalBal = address(this).balance;
        yETH.withdrawETH(shareAmt);
        uint finalBal = address(this).balance;
        withdrewAmt = sub(finalBal, initalBal);
        (withdrawalFee, amtWithoutProfit, feeAmt) = calculateFee(controller, totalShares, shareAmt, sharePrice);
        withdrawalFee = sub(withdrawalFee, withdrewAmt);
        withdrawalFee = withdrawalFee > 10 ? withdrawalFee : 0;
    }

    function calculateFee(
        ControllerInterface controller,
        uint totalShare,
        uint burnShare,
        uint sharePrice
    ) internal view returns (uint _withdrawAmt, uint amtWithoutProfit, uint feeAmt) {
        _withdrawAmt = wmul(burnShare, sharePrice);
        uint depositAmt = controller.balanceOf(address(this));
        uint ratio = wdiv(burnShare, totalShare);
        amtWithoutProfit = wmul(depositAmt, ratio);
        uint profit = sub(_withdrawAmt, amtWithoutProfit);
        feeAmt = wmul(profit, controller.fee());
    }
}


contract BasicResolver is yEthHelpers {
    event LogDeposit(uint amount, uint gasFeeAmt);
    event LogWithdraw(uint amount, uint withdrawalFee, uint gasFeeAmt, uint feeAmt);

    function deposit(uint amount, uint gasFeeAmt) external payable {
        ControllerInterface controller = ControllerInterface(getControllerAddr());
        require(gasFeeAmt <= controller.maxGasFeeAmount(), "max-fee-amount");
        yEthInterface yETH = yEthInterface(getYEthAddress());
        uint balAmt = sub(address(this).balance, gasFeeAmt);
        uint _amt = amount >= balAmt ? balAmt : amount;

        yETH.depositETH.value(_amt)();

        controller.deposit(_amt);
        payable(controller.gasFeeCollector()).transfer(gasFeeAmt);
        emit LogDeposit(_amt, gasFeeAmt);
    }

    function withdraw(uint amount, uint gasFeeAmt) external payable {
        ControllerInterface controller = ControllerInterface(getControllerAddr());
        yEthInterface yETH = yEthInterface(getYEthAddress());
        require(gasFeeAmt <= controller.maxGasFeeAmount(), "max-fee-amount");
        (uint withdrewAmt, uint withdrawalFee, uint amtWithoutProfit, uint feeAmt) = _withdrawAndCalculateFee(
            yETH,
            controller,
            amount
        );
        controller.withdraw(amtWithoutProfit);
        payable(controller.feeCollector()).transfer(feeAmt);
        payable(controller.gasFeeCollector()).transfer(gasFeeAmt);
        emit LogWithdraw(withdrewAmt, withdrawalFee, gasFeeAmt, feeAmt);
    }

}