// SPDX-License-Identifier: CC-BY-NC-ND-3.0

pragma solidity ^0.8.0;
import "../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract CITY_POLY is ERC20
{

  constructor() ERC20("SecondCity","CITY"){
    admin = 0x139228beD288c0f81353FDDaFD86b366799a6D4C;
  }

  address private admin;

  modifier ADMIN(){
    require(admin == msg.sender,"admin only");_;
  }

  function check_admin(address i) public view returns(bool) {
    return admin == i;
  }

  function set_admin(address i) public ADMIN {
    admin = i;
  }

  bool private mint_completed = false;

  function set_mint_completed() public ADMIN{
    mint_completed = true;
  }

  function get_mint_completed() public view returns(bool){
    return mint_completed;
  }

  function mint(uint256 amount) public ADMIN{
    require(!mint_completed,"mint completed");
    _mint(msg.sender,amount);
  }

  mapping(address => bool) private locked_account;
  function get_locked_account(address to) public view returns (bool){
    return locked_account[to];
  }

  mapping(address => uint256) private withdrawal_limit;
  uint256 private total_withdrawal_limit;

  function mint_withdrawal_limit(address to, uint256 amount) public ADMIN {
    locked_account[to] = true;
    withdrawal_limit[to] = withdrawal_limit[to] + amount;
    total_withdrawal_limit = total_withdrawal_limit + amount;
  }

  function get_withdrawal_limit(address to) public view returns (uint256){
    return withdrawal_limit[to];
  }

  function get_total_withdrawal_limit() public view returns (uint256){
    return total_withdrawal_limit;
  }

  function _check_withdrawable(address to, uint256 amount) 
  private view returns (bool) {
    if(locked_account[to]) 
    {
      if(withdrawal_limit[to] >= amount) return true;
      return false;
    }
    return true;
  }

  function _sub_withdrawal(address to, uint256 amount) internal{
      if(locked_account[to])
      {
        withdrawal_limit[to] = withdrawal_limit[to] - amount;
        total_withdrawal_limit = total_withdrawal_limit - amount;
      }
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
      require(_check_withdrawable(msg.sender,amount),"cannot withdraw");
      _transfer(msg.sender, to, amount);
      _sub_withdrawal(msg.sender, amount);
      return true;
  }

  function transferFrom(
      address from,
      address to,
      uint256 amount
  ) public override returns (bool) {

      require(_check_withdrawable(from,amount),"cannot withdraw");
      _spendAllowance(from, msg.sender, amount);
      _transfer(from, to, amount);
      _sub_withdrawal(from, amount);
      return true;
  }

  function burn(uint256 amount) public {
    require(_check_withdrawable(msg.sender,amount),"cannot burn");
    _burn(msg.sender,amount);
    _sub_withdrawal(msg.sender, amount);
  }
}