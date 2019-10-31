pragma solidity >=0.4.22 <0.6.0;
import "./IRMcontract.sol";

contract ASIcontract {
    address private owner;
    address private admin;
    address public registry;
    
    bool private disabled;
    address public irmaddress;
    //contract IRM irm; 
    struct peer {
        uint32 peernum;
        uint8 flag;
        bool isPeer;
        uint8 relation;
    }
    
    mapping(uint32 => peer) private peers;
    
    constructor(address _owner,address _irmaddress) public payable{
        
        owner = _owner;
        admin = _owner;
        registry = msg.sender;
        irmaddress = _irmaddress;
        disabled = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdminOrOwner(){
        require(msg.sender == admin || msg.sender == owner);
        _;
    }
    
    // add peer neighbor
    function addPeer(uint32 ASN, uint8 _flag, uint8 _relation) external onlyAdminOrOwner{
        peers[ASN].peernum = ASN;
        peers[ASN].isPeer = true;
        peers[ASN].flag = _flag;
        peers[ASN].relation = _relation;
    }
    
    
    function removePeer(uint32 ASN)  external onlyAdminOrOwner{
        delete peers[ASN];
    }
    
    function checkPeer(uint32 ASN) public view returns (bool){
        if (peers[ASN].isPeer) 
            return true;
        else 
            return false;
        
    }
    
    function getFlag(uint32 ASN) public view returns (uint8){
        return peers[ASN].flag;
    }
    
    function disable() external onlyOwner {
        disabled = true;
    }
    
    function enable() external onlyOwner {
        disabled = false;
    }
    
    function isDisabled() public view returns (bool){
        return disabled;
    }
    
    function getIRM() public view returns(address)
    {
        return irmaddress;
    }
    
    function policyCheck(uint8[] memory flagList, uint32 AS1) public view returns (bool){
        uint8 relation = peers[AS1].relation;
        int flag = 1;
        if (relation  == 0)  //as1 is customer of as0
        {
            for (uint i =0; i < flagList.length; i++)
            {
                if (flagList[i] != 0) return false;
            }
            
        }
        else if (relation == 1)  //as1 is peer of as0
        {
            for (uint i =1; i < flagList.length; i++)
            {
                if (flagList[i] != 0) return false;
            }
        }
        else  //as1 is provider of as0
        {
            for (uint i =0; i < flagList.length; i++)
            {
                if(flag ==1){
                    if (flagList[i] != flag) flag =0;
                }
                else{
                    if (flagList[i] != flag) return false;
                }
            }
        }
        return true;
    }
    
   function updateFlag(uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 wNum, uint32[] memory ASpath) public onlyAdminOrOwner returns (bool){
        uint ASpathLen = ASpath.length;
        uint8[] memory flagList = new uint8[](ASpathLen);
        uint32 ASorigin = ASpath[ASpathLen-1];
	    flagList[0] = peers[ASpath[1]].flag;  
        IRMcontract irm = IRMcontract(irmaddress);
        bool isPrefix = irm.hasPrefix(ASorigin, ipStr1, ipStr2, ipStr3, ipStr4, wNum);
	    if(isPrefix==true){
         for (uint i = 1; i < ASpathLen; i++){

            uint32 ASn = ASpath[i];
            address ASnCtraddr = irm.getASI(ASn);
            ASIcontract ASnCtr = ASIcontract(ASnCtraddr);

            if (i != ASpathLen-1)
            {
                bool beforPeer = ASnCtr.checkPeer(ASpath[i-1]);
                bool afterPeer = ASnCtr.checkPeer(ASpath[i+1]);
                flagList[i] = ASnCtr.getFlag(ASpath[i+1]);
                if (beforPeer == false || afterPeer == false)
                    return false;
            }
            else
            {
                bool beforPeer = ASnCtr.checkPeer(ASpath[i-1]);
                if (beforPeer == false) 
                    return false;
            }

        }
	}else{
		return false;
}
        return policyCheck(flagList,ASpath[1]);
    }

        
}
 
