pragma solidity ^0.7.3;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Compound.sol';

contract Wallet is Compound {
    address public admin;

    constructor(
        address _comptroller,
        address _cEthAddress
    ) Compound(_comptroller, _cEthAddress) {
        admin = msg.sender;
    }

    function deposit(
        address cTokenAdddress,
        uint underlyingAmount
    ) external {
        address underlyingAddress = getUnderlyingAddress(cTokenAdddress);
        IERC20(underlyingAddress).transferFrom(msg.sender, address(this), underlyingAmount);
        supply(cTokenAdddress, underlyingAmount);
    }

    function withdraw(
        address cTokenAddress,
        uint underlyingAmount,
        address recipient
    ) onlyAdmin() external {
        require(
            getUnderlyingBalance(cTokenAddress) >= underlyingAmount, 'balance too low'
        );
        claimComp();
        redeem(cTokenAddress, underlyingAmount);

        address underlyingAddress = getUnderlyingAddress(cTokenAddress);
        IERC20(underlyingAddress).transfer(recipient, underlyingAmount);

        address compAddress = getCompAddress();
        IERC20 compToken = IERC20(compAddress);
        uint compAmount = compToken.balanceOf(address(this));
        compToken.transfer(recipient, compAmount);
    }

    function withdrawEth(
        uint underlyingAmount,
        address payable recipient
    ) onlyAdmin() external {
         require(
            getUnderlyingEthBalance() >= underlyingAmount, 'balance too low'
        );
        claimComp();
        redeemEth(underlyingAmount);
        recipient.transfer(underlyingAmount);

        address compAddress = getCompAddress();
        IERC20 compToken = IERC20(compAddress);
        uint compAmount = compToken.balanceOf(address(this));
        compToken.transfer(recipient, compAmount);
    }

    receive() external payable {
        supplyEth(msg.value);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
}