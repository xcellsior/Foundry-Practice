//write in solidity
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18; 

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

// 'is Test' is required to use the test library functions like assertEq()
contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); 

    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000 i didnt check this but that should be 17 0s
    uint256 constant START_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // our fundMe variable of type FundMe is a new FundMe contract
        
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // input paramater = sepolia price feed addr
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run(); // This is running the func in deploy script
        // then fund the user with some ether
        vm.deal(USER, START_BALANCE);
    }

    function testMinDollarIsFive() public {
       assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // expect the next line to revert
        vm.expectRevert();
        fundMe.fund(); // send 0
    }

    function testFundUpdatesDataStructure () public {
        vm.prank(USER); // means next tx will be sent by USER

        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //grab the eth balance of the owner at the beginning
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //pretend to be the owner
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we are just making sure we don't spoof the null address 
        // there are weird sanity checks in random places that prevent null addr from doing stuff that we want to avoid


        // The default gas price on a local anvil chain is 0
        // for us to simulate this, we have to tell teh test to use it
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // prank a new addr
            // give it money, then fund
            // you can use the cheatcode "hoax" to set up a wallet and fund at the same time
            hoax (address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; //grab the eth balance of the owner at the beginning
        uint256 startingFundMeBalance = address(fundMe).balance;


        // Act
        uint256 gasStart = gasleft(); // gasleft() is a built in solidity func that tells how much gas is left
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        assert (address(fundMe).balance == 0);
        assert (startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we are just making sure we don't spoof the null address 
        // there are weird sanity checks in random places that prevent null addr from doing stuff that we want to avoid


        // The default gas price on a local anvil chain is 0
        // for us to simulate this, we have to tell teh test to use it
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // prank a new addr
            // give it money, then fund
            // you can use the cheatcode "hoax" to set up a wallet and fund at the same time
            hoax (address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; //grab the eth balance of the owner at the beginning
        uint256 startingFundMeBalance = address(fundMe).balance;


        // Act
        uint256 gasStart = gasleft(); // gasleft() is a built in solidity func that tells how much gas is left
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        assert (address(fundMe).balance == 0);
        assert (startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }


}