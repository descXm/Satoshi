// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SatToken is ERC20 {

    using SafeMath for uint256;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 constant DOMAIN_TYPE_HASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 constant PERMIT_TYPE_HASH = keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");

    mapping (address => uint) public nonces;
    address underlyingToken_;
    bool isActive_;
    uint256 satUnit_;

    constructor(uint256 chainId, address underlyingToken, uint256 satUnit) public ERC20("Satoshi", "SAT") {    
        require(isActive_ != true, "invalid status");
        isActive_ = true;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes("Satoshi")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        underlyingToken_ = underlyingToken;
        satUnit_ = satUnit;
    }

    function sat(uint256 amount, address receiver) external returns(bool){
        uint256 tempAmount = ERC20(underlyingToken_).balanceOf(msg.sender);
        uint256 mintAmount = tempAmount.sub(amount);
        if(mintAmount >= 0) {
            mintAmount = amount;
        }else{
            mintAmount = tempAmount;
        }
        require(ERC20(underlyingToken_).transferFrom(msg.sender, address(this), mintAmount));
        mintAmount = mintAmount.mul(satUnit_);
        _mint(receiver, mintAmount);
        return true;
    }

    function unsat(uint256 amount, address receiver) external returns(bool){
        uint256 tempAmount = balanceOf(msg.sender); 
        uint256 burnAmount = tempAmount.sub(amount);
        if(burnAmount >= 0) {
            burnAmount = amount;
        }else{
            burnAmount = tempAmount;
        }

        _burn(msg.sender, burnAmount);
        burnAmount = burnAmount.div(satUnit_);
        require(ERC20(underlyingToken_).transfer(receiver, burnAmount));
        return true;
    }
    
    function permit(address owner,address spender, uint256 nonce, uint256 expiry, uint256 amount, uint8 v, bytes32 r, bytes32 s) external  returns(bool){

        require(owner != address(0), "invalid owner address");
        require(expiry == 0 || now <= expiry, "permit expired");
        require(nonce == nonces[owner]++, "invalid nonce");

        bytes32  digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH,
                                     owner,
                                     spender,
                                     amount,
                                     nonce,
                                     expiry))
        ));
        
        require(owner == ecrecover(digest, v, r, s), "invalid permit");
        _approve(owner, spender, allowance(owner, spender).add(amount));
        nonces[owner] = nonce + 1;
        return true;
    }
}