pragma solidity >=0.4.22 <0.6.0;
import "./ASIcontract.sol";

contract IRMcontract {
    address public ownerICANN;

    constructor() public payable{
        ownerICANN = msg.sender;
    }

    modifier onlyOwnerICANN(){
        require(msg.sender == ownerICANN ,"Only ownerICANN can call this function.");
        _;
    }

    struct IPB 
    {
        uint32 IPstr; //IP前缀
        uint8 wNum; //8~24位掩码
        uint32 ASN;
	    State state;
        address owner;
        address lease;
    }

    struct ASNData
    {
        address owner;
        address asiContract; //ASI合约
        //IPB[] IPBlock;
        uint stime;
        uint IPBindex;
        uint period;
    }
    
    event Register
    (
    	uint8 ipStr1,
    	uint8 ipStr2,
    	uint8 ipStr3,
    	uint8 ipStr4,
    	uint8 wNum
    );
    
    event Delegate
    (
        uint8 ipStr1,
    	uint8 ipStr2,
    	uint8 ipStr3,
    	uint8 ipStr4,
    	uint8 wNum,
    	address delegatee
    );
    
    event Allocate
    (
        address owner,
        uint8 ipStr1,
    	uint8 ipStr2,
    	uint8 ipStr3,
    	uint8 ipStr4,
    	uint8 wNum,
    	address lease
    );
    
    event Revoke
    (
        uint8 ipStr1,
    	uint8 ipStr2,
    	uint8 ipStr3,
    	uint8 ipStr4,
    	uint8 wNum,
    	address lease    
    );
    
    mapping(uint32 => ASNData) public ROA;
    
    //register AS and create ASIcontract
    function registerAS(uint32 ASN) public payable onlyOwnerICANN 
    {
        require (address(ROA[ASN].owner) == address(0));

        ASIcontract asi = new ASIcontract(ownerICANN,address(this));
        ROA[ASN].asiContract = address(asi);
	    ROA[ASN].owner = ownerICANN;
	    ROA[ASN].stime = now;
        ROA[ASN].period = 500;

    }
    
    function getASI(uint32 ASN) public view returns (address){
         
        return ROA[ASN].asiContract;
    }
    
    
    function updateAS(uint32 ASN, uint IPBindex) public returns(bool success)
    {
        require((msg.sender == ROA[ASN].owner) && (msg.sender == currentIPBs[IPBindex].owner));
        ROA[ASN].IPBindex = IPBindex;
        return true;
    }
    
    //allocate AS and create ASIcontract
    function allocateAS(uint32 ASN, address ASowner) public 
    {
        require(msg.sender == ROA[ASN].owner) ;
        ASIcontract asi = new ASIcontract(ASowner,address(this));
        ROA[ASN].asiContract = address(asi);
	    ROA[ASN].owner = ASowner;
	    ROA[ASN].stime = now;
        ROA[ASN].period = 500;
        //ROA[ASN].asiContract = new ASI(ASowner);
        //ASI asi = new ASI(ASowner);
        //ROA[ASN].asiContract = asi;
    }
    
    uint32 IP_str;
    IPB[] public currentIPBs;
    int flag;
    uint index_d;
    enum State {Registered, Delegated, Allocated, Revoked}

    function covertIP(uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4) public returns (uint32)
    {
        IP_str = uint32(ipStr1)*256+uint32(ipStr2);
        IP_str = IP_str*256+uint32(ipStr3);
        IP_str = IP_str*256+uint32(ipStr4);

        return IP_str;
    }
    
    /*function covertfromIP() public view returns (uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4) 
    {
    	ipStr4 = uint8 (IP_str) & uint8(255);
    	ipStr3 = uint8 (IP_str >> 8) & uint8(255);
    	ipStr2 = uint8 (IP_str >> 16) & uint8(255);
    	ipStr1 = uint8 (IP_str >> 24) & uint8(255);
    }*/
    
    function IPB_next(uint32 str_ip,uint8 w_num) public returns (uint32)
    {
        IP_str = str_ip >> (uint (32 - w_num));
        IP_str++;
        IP_str = str_ip << (uint (32 - w_num));
        return IP_str;
    }
    
    function IPB_check(uint32 ip_str,uint8 w_num) public returns(int)
    {
        for (uint i = 0; i < currentIPBs.length; i++)
		 {
			if (currentIPBs[i].IPstr > ip_str)
				{
					if (IPB_next(currentIPBs[i-1].IPstr,currentIPBs[i-1].wNum) > ip_str)
					{
                        flag = int (i-1);
						return flag;
					}
					else if (IPB_next(ip_str,w_num) > currentIPBs[i].IPstr)
					{
                        flag=-1;
						return flag;
					}
					else
					{
                        flag=-1;
                        return flag;
					}
				}
            else if ((currentIPBs[i].IPstr == ip_str))
            {
                if(currentIPBs[i].wNum > w_num)
                {
                    flag=-1;
                    return flag;
                }else
                {
                    flag=int (i);
                    return flag;
                }
            }
		}
        flag=-1;
		return flag;
	}
    
    function IPB_exist(uint32 ip_str,uint8 w_num) public returns (int)
    {
        uint i;
	    for(i = 0; i < currentIPBs.length; i++)
	    {
	        if(currentIPBs[i].IPstr > ip_str)
	        {
	            if(i==0)
	            {
	                flag = 0;
	                return flag;
	            }else if(IPB_next(currentIPBs[i-1].IPstr,currentIPBs[i-1].wNum) > ip_str)
	            {
	                flag = -1;
	                return flag;
	            }else if(IPB_next(ip_str,w_num) > currentIPBs[i].IPstr)
	            {
	                flag = -1;
	                return flag;
	            }else
	            {
	                flag = int(i);
	                return flag;
	            }
	        }else if(currentIPBs[i].IPstr == ip_str)
	        {
	            if(currentIPBs[i].wNum <= w_num)
	            {
	                flag = -1;
	                return flag;
	            }else
	            {
	                flag = int(i);
	                return flag;
	            }
	        }
	    }
	    flag = int(i);
	    return flag;
    }
    
    function IPB_divide(uint index, uint32 ip_str, uint8 w_num) public returns (uint)
    {
        require(msg.sender == currentIPBs[index].owner);
        require(currentIPBs[index].wNum < w_num);
        require(currentIPBs[index].IPstr <= ip_str);
        require(currentIPBs[index].IPstr >> (32 - currentIPBs[index].wNum) == (ip_str >> (32 - currentIPBs[index].wNum)));
        
        IPB[] memory IPBadd = new IPB[](32);
        uint32 indexIP = currentIPBs[index].IPstr;
        uint8 i = 0;
        uint8 new_wnum = 0;
		index_d = 0;
        uint index_x = w_num-currentIPBs[index].wNum-1;
        int flagd = 0;
		while(i < w_num - currentIPBs[index].wNum)
		{
			if((ip_str >> (32 - currentIPBs[index].wNum-i-1)) & 1 == 0)
			{
				IPBadd[index_x].IPstr = IPB_next(indexIP,currentIPBs[index].wNum+i+1);
				IPBadd[index_x].wNum = currentIPBs[index].wNum+i+1;
				IPBadd[index_x].ASN = currentIPBs[index].ASN;
				IPBadd[index_x].state = currentIPBs[index].state;
				IPBadd[index_x].owner = currentIPBs[index].owner;
				IPBadd[index_x].lease = currentIPBs[index].lease;
                index_x--;
			}
			else
			{
                if(flagd != 1)
                {
                    flagd = 1;
                    new_wnum = i + 1;
                }
                
                indexIP = IPB_next(indexIP,currentIPBs[index].wNum + i + 1);
        		IPBadd[index_d].IPstr = indexIP;
        		IPBadd[index_d].wNum = currentIPBs[index].wNum + i + 1;
        		
                while(((ip_str >> (32 - IPBadd[index_d].wNum - 1)) & 1 == 0) && (IPBadd[index_d].wNum < w_num))
                {
                    IPBadd[index_d].wNum++;
                }
                
                if(IPBadd[index_d].wNum < w_num)
                {
                    IPBadd[index_d].wNum++;
                }
                
                IPBadd[index_d].ASN=currentIPBs[index].ASN;
				IPBadd[index_d].state=currentIPBs[index].state;
				IPBadd[index_d].owner=currentIPBs[index].owner;
				IPBadd[index_d].lease=currentIPBs[index].lease;
                index_d++;
			}
            i++;
		}
		index_d = index_d + index;
        IPB_add(IPBadd,w_num-currentIPBs[index].wNum,index+1);
        if(flagd == 1)
        {
            currentIPBs[index].wNum = currentIPBs[index].wNum + new_wnum;
        }
        else 
        {
            currentIPBs[index].wNum = currentIPBs[index].wNum+i;
        }
        return index_d;
	}
    
    //IPB_add
    function IPB_add(IPB[] memory add_IPB,uint num,uint unum) internal 
    {
        uint i;
    	for( i = 0;i < num; i++)
    	{
    	    currentIPBs.push(IPB(add_IPB[i].IPstr,add_IPB[i].wNum,add_IPB[i].ASN,add_IPB[i].state,add_IPB[i].owner,add_IPB[i].lease));
    	    updateAS(add_IPB[i].ASN,currentIPBs.length-1);
    	}
    	
    	for(uint j = currentIPBs.length-1; j >= unum + num; j--)
    	{
    	    currentIPBs[j].IPstr = currentIPBs[j - num].IPstr;
    	    currentIPBs[j].wNum = currentIPBs[j - num].wNum;
    	    currentIPBs[j].ASN = currentIPBs[j - num].ASN;
    	    currentIPBs[j].state = currentIPBs[j - num].state;
    	    currentIPBs[j].owner = currentIPBs[j - num].owner;
    	    currentIPBs[j].lease = currentIPBs[j - num].lease;
            updateAS(currentIPBs[j - num].ASN,j);
    	}
    	
        for( i = unum; i < unum + num; i++)
        {
            currentIPBs[i].IPstr = currentIPBs[i - unum].IPstr;
    	    currentIPBs[i].wNum = currentIPBs[i - unum].wNum;
    	    currentIPBs[i].ASN = currentIPBs[i - unum].ASN;
    	    currentIPBs[i].state = currentIPBs[i - unum].state;
    	    currentIPBs[i].owner = currentIPBs[i - unum].owner;
    	    currentIPBs[i].lease = currentIPBs[i - unum].lease;
    	    updateAS(currentIPBs[i - unum].ASN,i);
        }
    }
    //IPB_delete
    function IPB_min(uint num, uint unum) public
    {
        require((num + unum) <= currentIPBs.length);
        for(uint i = num + unum; i < currentIPBs.length; i++)
        {
            currentIPBs[i-num].IPstr = currentIPBs[i].IPstr;
            currentIPBs[i-num].wNum = currentIPBs[i].wNum;
            currentIPBs[i-num].ASN = currentIPBs[i].ASN;
            currentIPBs[i-num].state = currentIPBs[i].state;
            currentIPBs[i-num].owner = currentIPBs[i].owner;
            currentIPBs[i-num].lease = currentIPBs[i].lease;
            updateAS(currentIPBs[i].ASN,i-num);
        }
        
        for(uint j = 0; j < num; j++)
        {
            delete ROA[currentIPBs[currentIPBs.length-1].ASN];
            delete currentIPBs[currentIPBs.length-1];
        }
        
        currentIPBs.length = currentIPBs.length - num;
    }
    
    function IPB_update(uint updatenum) public returns (uint)
    {
        uint index = updatenum;
        bool flag1 = true;
        bool flag2 = true;
        while(flag1 || flag2)
        {
            if((index > 0) && (IPB_next(currentIPBs[index-1].IPstr,currentIPBs[index-1].wNum)==currentIPBs[index+1].IPstr) 
            && (currentIPBs[index-1].wNum == currentIPBs[index].wNum)
            && (currentIPBs[index-1].ASN == currentIPBs[index].ASN)
            && (currentIPBs[index-1].owner == currentIPBs[index].owner)
            && (currentIPBs[index-1].lease == currentIPBs[index].lease)
            ){
                currentIPBs[index-1].wNum = currentIPBs[index].wNum - 1;
                IPB_min(1,index);
                index--;
                flag1 = true;
            }
            else
            {
                flag1 = false;
            }
            if((currentIPBs.length > (index+1)) && (IPB_next(currentIPBs[index].IPstr,currentIPBs[index].wNum)==currentIPBs[index+1].IPstr) 
            && (currentIPBs[index].wNum == currentIPBs[index+1].wNum)
            && (currentIPBs[index-1].ASN == currentIPBs[index].ASN)
            && (currentIPBs[index].owner == currentIPBs[index+1].owner)
            && (currentIPBs[index].lease == currentIPBs[index+1].lease)
            ){
                currentIPBs[index].wNum = currentIPBs[index].wNum - 1;
                IPB_min(1,index+1);
                flag2 = true;
            }
            else
            {
                flag2 = false;
            }
        }
        index_d = index;
        return index_d;
    }

    function registerPrefix(uint32 ASN, uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 w_num) external onlyOwnerICANN returns(uint)
    {
        require ((w_num<=24)&&(w_num>=8));
        IP_str = covertIP(ipStr1,ipStr2,ipStr3,ipStr4);
        IP_str = (IP_str>>(32-w_num))<<(32-w_num);
        
        int num = IPB_exist(IP_str,w_num);
        require(num >= 0);
        uint unum = uint(num);
        
        IPB[] memory RegIPB = new IPB[](1);
        RegIPB[0].IPstr = IP_str;
        RegIPB[0].wNum = w_num;
        RegIPB[0].ASN = ASN;
        RegIPB[0].state = State.Registered;
        RegIPB[0].owner = ownerICANN;
        RegIPB[0].lease = ownerICANN;
        IPB_add(RegIPB,1,unum);
        
        emit Register(ipStr1,ipStr2,ipStr3,ipStr4,w_num);
        return unum;

    }

    function delegatePrefix(uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 w_num, address delagatee) public
    {
        require ((w_num<=24)&&(w_num>=8));
        IP_str = covertIP(ipStr1,ipStr2,ipStr3,ipStr4);
        IP_str = (IP_str>>(32-w_num))<<(32-w_num);
        
        int num = IPB_check(IP_str,w_num);
        require(num >= 0);
        
        uint unum = uint(num);
        require((msg.sender == currentIPBs[unum].owner) && (currentIPBs[unum].state != State.Allocated));
        if((IP_str != currentIPBs[unum].IPstr) || w_num != currentIPBs[unum].wNum )
        {
            unum = IPB_divide(unum,IP_str,w_num);
        }
        currentIPBs[unum].owner = delagatee;
        currentIPBs[unum].lease = delagatee;
        currentIPBs[unum].state = State.Delegated;
        IPB_update(unum);
        emit Delegate(ipStr1,ipStr2,ipStr3,ipStr4,w_num,delagatee);
    }
    
    function assignPrefix(uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 w_num,address owner) public 
    {
        require ((w_num<=24)&&(w_num>=8));
        IP_str = covertIP(ipStr1,ipStr2,ipStr3,ipStr4);
        IP_str = (IP_str>>(32-w_num))<<(32-w_num);
        
        int num = IPB_exist(IP_str,w_num);
        require(num >= 0);
        uint unum = uint(num);
        
        require(msg.sender == currentIPBs[unum].owner);
        if(( IP_str!=currentIPBs[unum].IPstr) || ( w_num != currentIPBs[unum].wNum))
        {
		    unum = IPB_divide(unum, IP_str,w_num);            
        }

		currentIPBs[unum].lease=owner;
		currentIPBs[unum].state=State.Allocated;
		IPB_update(unum);
        emit Allocate(msg.sender,ipStr1,ipStr2,ipStr3,ipStr4,w_num,owner);

    }
    
    function checkPrefix(uint32 ASN, uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 w_num) public returns (int)
    {
        require ((w_num<=24)&&(w_num>=8));
        IP_str = covertIP(ipStr1,ipStr2,ipStr3,ipStr4);
        IP_str = (IP_str>>(32-w_num))<<(32-w_num);
        
        int num = IPB_check(IP_str,w_num);
        require(num >= 0);
        int flag_check;
        uint unum = uint(num);
        if(ROA[ASN].IPBindex == unum)
        {
            flag_check = 1;
            return flag_check;    
        }
        flag_check = -1;
        return flag_check;  
    }
    
    function revokePrefix(uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 w_num) external onlyOwnerICANN
    {
        require ((w_num<=24)&&(w_num>=8));
        IP_str = covertIP(ipStr1,ipStr2,ipStr3,ipStr4);
        IP_str = (IP_str>>(32-w_num))<<(32-w_num);
        
        int num = IPB_check(IP_str,w_num);
        require(num >= 0);
        uint unum = uint(num);
        
        currentIPBs[unum].owner = ownerICANN;
        emit Revoke(ipStr1,ipStr2,ipStr3,ipStr4,w_num,currentIPBs[unum].lease);
        currentIPBs[unum].lease = ownerICANN;
        currentIPBs[unum].state = State.Revoked;
        IPB_update(unum);
    }

    function hasPrefix(uint32 ASN, uint8 ipStr1, uint8 ipStr2, uint8 ipStr3, uint8 ipStr4, uint8 wNum) public returns(bool)
    {
        require (ROA[ASN].asiContract != address(0));
        int index = checkPrefix(ASN, ipStr1, ipStr2, ipStr3, ipStr4, wNum);
        if (index == -1)
            return false;
        else
            return true;
    }
    
}
