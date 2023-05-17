// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FakeUSDT is IERC20 {
    string public name = "Fake USDT";
    string public symbol = "FUSDT";
    uint8 public decimals = 18;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    
    uint256 totalTokenSupply = 1000000 * 10 ** uint256(decimals);
    
    constructor() {
        balances[msg.sender] = totalTokenSupply;
    }
    
    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[sender], "Insufficient balance");
        
        balances[sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");
        
        allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        address owner = sender;
        require(owner != address(0), "Invalid owner address");
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[owner], "Insufficient balance");
        require(amount <= allowances[owner][msg.sender], "Insufficient allowance");
        
        balances[owner] -= amount;
        balances[recipient] += amount;
        allowances[owner][msg.sender] -= amount;
        
        emit Transfer(owner, recipient, amount);
        
        return true;
    }
}
