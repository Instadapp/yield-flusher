pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface yEthInterface {
    function getPricePerFullShare() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function balance() external view returns (uint);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

interface ControllerInterface {
    function balanceOf(address) external view returns (uint);
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

}


contract BasicResolver is yEthHelpers {
    struct PosData {
        uint yEthBal;
        uint totalDeposit;
        uint userDeposit;
        uint available;
        uint sharePrice;
        uint nowBlock;
    }

    function getPosition(address user) public view returns(PosData memory posData) {
        yEthInterface yETH = yEthInterface(getYEthAddress());
        TokenInterface weth = TokenInterface(getAddressWETH());
        ControllerInterface controller = ControllerInterface(getControllerAddr());

        posData.yEthBal = yETH.balanceOf(user);
        posData.totalDeposit = yETH.balance();
        posData.userDeposit = controller.balanceOf(user);
        posData.available = weth.balanceOf(address(yETH));
        posData.sharePrice = yETH.getPricePerFullShare();
        posData.nowBlock = block.number;
    }
}