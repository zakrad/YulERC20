// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Used in the `name()` function
// "Yul Token"
bytes32 constant nameLength = 0x0000000000000000000000000000000000000000000000000000000000000009;
bytes32 constant nameData = 0x59756c20546f6b656e0000000000000000000000000000000000000000000000;

// Used in the `symbol()` function
// "YUL"
bytes32 constant symbolLength = 0x0000000000000000000000000000000000000000000000000000000000000003;
bytes32 constant symbolData = 0x59554c0000000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientBalance()"))`
bytes32 constant insufficientBalanceSelector = 0xf4d678b800000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientAllowance(address,address)"))`
bytes32 constant insufficientAllowanceSelector = 0xf180d8f900000000000000000000000000000000000000000000000000000000;

error InsufficientBalance();
error InsufficientAllowance(address owner, address spender);

bytes32 constant transferHash = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
bytes32 constant approvalHash = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

uint256 constant maxUint256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
/// @title Yul ERC20
/// @author Zakrad
/// @notice For demo purposes ONLY.
contract YulERC20 {

  event Transfer(address indexed sender, address indexed receiver, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  // owner -> balance
  mapping(address => uint256) internal _balances;
  // owner -> sender -> allowance
  mapping(address => mapping(address => uint256)) internal _allowance;

  uint256 internal _totalSupply;

  constructor() {
    assembly {
      mstore(0x00, caller())
      mstore(0x20, 0x00)
      let slot := keccak256(0x00, 0x40)
      sstore(slot, maxUint256)

      sstore(0x02, maxUint256)

      mstore(0x00, maxUint256)
      log3(0x00, 0x20, transferHash, 0x00, caller())

    }

  }

  function name() public pure returns (string memory) {
    assembly{
      let memptr := mload(0x40)
      mstore(memptr, 0x20)
      mstore(add(memptr, 0x20), nameLength)
      mstore(add(memptr, 0x40), nameData)
      return(memptr, 0x60)
    }
  }

  function symbol() public pure returns (string memory) {
    assembly {
      let memptr := mload(0x40)
      mstore(memptr, 0x20)
      mstore(add(memptr, 0x20), symbolLength)
      mstore(add(memptr, 0x40), symbolData)
      return(memptr, 0x60)
    }
  }

  function totalSupply() public view returns (uint256) {
    assembly {
      mstore(0x00, sload(0x02))
      return(0x00, 0x20)
    }
  }

  function decimals() public pure returns (uint8) {
    assembly{
      mstore(0, 18)
      return(0x00, 0x20)
    }
  }

  function balanceOf(address) public view returns(uint256) {
    assembly{
      // let account := calldataload(4)

      mstore(0x00, calldataload(4))
      mstore(0x20, 0x00)
      // let hash := keccak256(0x00, 0x40)

      // let accountBalance := sload(keccak256(0x00, 0x40))

      mstore(0x00, sload(keccak256(0x00, 0x40)))
      return(0x00, 0x20)
    }
  }

  function transfer(address receiver, uint256 value) public returns(bool) {
    assembly{
      // mem stuff
      let memptr := mload(0x40)

      // load caller balance, assert sifficient
      mstore(memptr, caller())
      mstore(add(memptr, 0x20), 0x00)
      let callerBalanceSlot := keccak256(memptr, 0x40)
      let callerBalance := sload(callerBalanceSlot)

      if lt(callerBalance, value) {
        mstore(0x00, insufficientBalanceSelector)
        revert(0x00, 0x04)
        // revert(0x00, 0x20)  same
      }

      if eq(caller(), receiver) {
        revert(0x00, 0x00)
      }

      // decrease caller balance
      let newCallerBalance := sub(callerBalance, value)
      sstore(callerBalanceSlot, newCallerBalance) 
      
      // overriding caller memory cause no need for it
      //load receiver balance
      mstore(memptr, receiver)
      mstore(add(memptr, 0x20), 0x00)

      let receiverBalanceSlot := keccak256(memptr, 0x40)
      let receiverBalance := sload(receiverBalanceSlot)


      // increase receiver balance
      let newReceiverBalance := add(receiverBalance, value)

      // store
      sstore(receiverBalanceSlot, newReceiverBalance)

      // log
      mstore(0x00, value)
      log3(0x00, 0x20, transferHash, caller(), receiver)


      mstore(0x00, 0x01) //true value
      return(0x00, 0x20) 
    }
  }

  function allowance(address owner, address spender) public view returns(uint256) {
    assembly{
      // keccack256(spender, (keccack256(owner, slot)))
      mstore(0x00, owner)
      mstore(0x20, 0x01)
      let innerHash := keccak256(0x00, 0x40)

      mstore(0x00, spender)
      mstore(0x20, innerHash)
      let allowanceSlot := keccak256(0x00, 0x40)

      let allowanceValue := sload(allowanceSlot)
      mstore(0x00, allowanceValue)
      return(0x00, 0x20)
    }
  }

  function approve(address spender, uint256 amount) public returns(bool) {
    assembly {      
      mstore(0x00, caller())
      mstore(0x20, 0x01)
      let innerHash := keccak256(0x00, 0x40)

      mstore(0x00, spender)
      mstore(0x20, innerHash)
      let allowanceSlot := keccak256(0x00, 0x40)

      sstore(allowanceSlot, amount)

      mstore(0x00, amount)
      log3(0x00, 0x20, approvalHash, caller(), spender)

      mstore(0x00, 0x01)
      return(0x00, 0x20)      
    }
  }

  function transferFrom(address sender, address receiver, uint256 amount) public returns (bool) {
    assembly {
      let memptr := mload(0x40)

      mstore(0x00, sender)
      mstore(0x20, 0x01)
      let innerHash := keccak256(0x00, 0x40)

      mstore(0x00, caller())
      mstore(0x20, innerHash)
      let allowanceSlot := keccak256(0x00, 0x40)

      let callerAllowance := sload(allowanceSlot)

      if lt(callerAllowance, amount) {
        mstore(memptr, insufficientAllowanceSelector)
        mstore(add(memptr, 0x04), sender)
        mstore(add(memptr, 0x24), caller())
        revert(memptr, 0x44)
      }

      if lt(callerAllowance, maxUint256) {
        sstore(allowanceSlot, sub(callerAllowance, amount))
      }

      // load sender balance, assert sifficient
      mstore(memptr, sender)
      mstore(add(memptr, 0x20), 0x00)
      let senderBalanceSlot := keccak256(memptr, 0x40)
      let senderBalance := sload(senderBalanceSlot)

      if lt(senderBalance, amount) {
        mstore(0x00, insufficientBalanceSelector)
        revert(0x00, 0x04)
        // revert(0x00, 0x20)  same
      }
      
      sstore(senderBalanceSlot, sub(senderBalance, amount))

      //receiver balance
      mstore(memptr, receiver)
      mstore(add(memptr, 0x20), 0x00)
      let receiverBalanceSlot := keccak256(memptr, 0x40)
      let receiverBalance := sload(receiverBalanceSlot)

      sstore(receiverBalanceSlot, add(receiverBalance, amount))

      mstore(0x00, amount)
      log3(0x00, 0x20, transferHash, sender, receiver)

      mstore(0x00, 0x01)
      return(0x00, 0x20)
    }
  }

}