// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "./metatx/EIP712MetaTransaction.sol";
import "./RabbitRocket.sol";
import "./RabbitCreed.sol";
import "./RabbitGreed.sol";
import "./RabbitFancier.sol";
import "./RabbitBreed.sol";
import "./czodiac/CZodiacNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract RabbitCatchMaster is Ownable, EIP712MetaTransaction {
    using Address for address payable;

    RabbitRocket public rabbitRocket;
    RabbitCreed public rabbitCreed;
    RabbitGreed public rabbitGreed;
    RabbitFancier public rabbitFancier;
    RabbitBreed public rabbitBreed;

    CZodiacNFT public czodiacNFT;

    uint256 public constant priceStart = 0.1 ether;
    uint256 public constant priceIncrement = 0.1 ether;
    uint256 public constant mintCountPriceIncrement = 100;
    uint256 public constant mintCountMax = 2500;
    uint256 public mintCount;

    mapping(address=>bool) whitelist;
    uint256 public constant whitelistMintCap = 5; 

    constructor(RabbitRocket _rabbitRocket, RabbitCreed _rabbitCreed, RabbitGreed _rabbitGreed, RabbitFancier _rabbitFancier, RabbitBreed _rabbitBreed, CZodiacNFT _czodiacNFT) EIP712MetaTransaction("@RabbitCatch/RabbitCatchMaster","1.0.0") Ownable() {
        rabbitRocket = _rabbitRocket;
        rabbitCreed = _rabbitCreed;
        rabbitGreed = _rabbitGreed;
        rabbitFancier = _rabbitFancier;
        rabbitBreed = _rabbitBreed;

        czodiacNFT = _czodiacNFT;        
    }

    function getPrice() public view returns (uint256 _price) {
        return priceStart + (priceIncrement)*(mintCount/mintCountPriceIncrement);
    }

    function canMint(address _for) public view returns (bool _canMint) {
        if(mintCount > mintCountMax) return false;
        if(rabbitRocket.isOver()) return false;
        if(block.timestamp < rabbitRocket.whitelistEndEpoch()) {
            if(whitelist[_for]) {
                return rabbitGreed.totalBuys(_for) < whitelistMintCap;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    function mint(address _for, string calldata _code) external payable {
        require(canMint(_for), "RabbitCatchMaster: Cannot Mint");
        require(msg.value == getPrice(), "RabbitCatchMaster: Invalid BNB Value");
        //TODO: Mint and transfer NFT after generating zodiacId and tokenURI
        //czodiacNFT.mintmint(string memory tokenURI_, uint256 zodiacId);
        uint256 tenPct = msg.value/10;
        rabbitRocket.timerReset{value:tenPct}(_for);
        if(bytes(_code).length != 0) {
            rabbitCreed.addRewards{value:tenPct}(_code);
        }
        rabbitGreed.increaseTotalBuys{value:tenPct}(_for,1);
        rabbitFancier.addToRewards{value:tenPct}();
        rabbitBreed.addToRewards{value:tenPct}();
        payable(owner()).sendValue(address(this).balance);        
    }

}