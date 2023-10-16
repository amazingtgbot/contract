// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
// import "hardhat/console.sol";
pragma experimental ABIEncoderV2;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IBotRouter{
    function feeTokens(address token) external returns(bool);
}

import "./BasicOrder.sol";

contract LimitOrder is ReentrancyGuard, BasicOrder {

    using SafeMath for uint256;

    struct OrderInfo {
        uint256 amountIn;
        address[] path;
        uint256 amountOutMin;
        uint256 deadline;
        uint state;                      // 1 pending 2 success 3 cancle 
        address user;          
    }

    /// @notice user info mapping
    mapping(address => uint256[]) public usersOrders;
    mapping(uint256 => OrderInfo) public orders;
    // mapping(uint256 => address) public orderIdToAddress;
    uint256 public currentOrderId = 1;
    
    uint256 public transactionFee = 0.01 ether;

    address public botRouter;

    constructor(address _factory, address _WETH) BasicOrder(_factory,_WETH){}

    function setBotRouter(address _router) public onlyOwner{
        require(_router != address(0),"Invalid address");
        botRouter = _router;
    }

    function makeOrder(uint256 _amountIn, address[] calldata _path, uint256 _amountOutMin, uint256 _deadline) public payable nonReentrant{
        require(_path.length >= 2, "LimitOrder: INVALID_PATH");
        require(_amountIn > 0 && _amountOutMin > 0 ,"LimitOrder: Invalid amount");
        uint256 fee = transactionFee;
        if(_path[0] == WETH){
            fee += _amountIn;
        }else{
            uint256 allowance = IERC20(_path[0]).allowance(msg.sender, address(this));
            require(allowance >= _amountIn,'LimitOrder: Increase Allowance');
        }
        require(msg.value == fee, 'LimitOrder: INVALID_VALUE');
        
        orders[currentOrderId] = OrderInfo({
            amountIn: _amountIn,
            path: _path,
            amountOutMin: _amountOutMin,
            deadline: block.timestamp +_deadline,
            state: 1,
            user: msg.sender

        });
        usersOrders[msg.sender].push(currentOrderId);
        currentOrderId += 1;
    }

    function cancelOrder(uint256 _orderId) public {
        OrderInfo memory order = orders[_orderId];
        require(order.state == 1,"Invalid state!");
        require(order.deadline > 0, "Invalid Order!");
        if(block.timestamp < order.deadline){
            require(order.user == msg.sender,"Failed!");
        }
        _deleteOrder(order, _orderId, 3);
    }

    function timestamp() public view returns(uint256){
        return block.timestamp;
    }

    function _deleteOrder(OrderInfo memory  order, uint256 _orderId, uint _state) internal{
        orders[_orderId].state = _state;
        if(_state == 3){                // cancel
            _sendToken(order.path[0], order.user, order.amountIn);
        }
    }

    function _sendToken(address tokenAddress,address to, uint256 amount) internal  {
        if(tokenAddress != WETH){
            TransferHelper.safeTransfer(tokenAddress, to, amount);
        }else{
            _safeTransferETH(msg.sender,amount);
        }
	}

    function _safeTransferETH(address to, uint value) private {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function fromEthNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
       
        swapExactETHForTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function fromEthOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");

        swapExactETHForTokensSupportingFeeOnTransferTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function toEthNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        swapExactTokensForETH(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function toEthOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        swapExactTokensForETHSupportingFeeOnTransferTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function tokenToTokenNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        bool isFrom = true;
        if(IBotRouter(botRouter).feeTokens(order.path[0]) == false && IBotRouter(botRouter).feeTokens(order.path[order.path.length-1]) == true){
            isFrom = false;
        }
        swapExactTokensForTokens(isFrom, order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function tokenToTokenOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        bool isFrom = true;
        if(IBotRouter(botRouter).feeTokens(order.path[0]) == false && IBotRouter(botRouter).feeTokens(order.path[order.path.length-1]) == true){
            isFrom = false;
        }
        swapExactTokensForTokensSupportingFeeOnTransferTokens(isFrom, order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    /**
        ****************************** check functions ******************************
     */

    function getUserOrdersInfo(address user) public view returns(OrderInfo[] memory){
        
        uint256[] memory orderIds = usersOrders[user];
        uint256 length = orderIds.length;
        OrderInfo[] memory userOrders = new OrderInfo[](length);
        for(uint256 i=0;i<length;i++){
            uint256 id = orderIds[i];
            OrderInfo memory order = orders[id];
            userOrders[i] = order;
        }
        return userOrders;
    }

    function getOrderState(uint256 _orderId) public returns(string memory){
        OrderInfo memory order = orders[_orderId];
        if(order.deadline < block.timestamp || order.deadline == 0 || order.state == 2){
            return "";
        }else if (order.state == 3){
            return "cancel";
        }
        address[] memory path = order.path;
        if(path[0] == WETH){
            return tryFromEth(_orderId);
        }else if (path[path.length-1] == WETH){
            return tryToEth(_orderId);
        }else{
            return tryTokenToToken(_orderId);
        }
    }

    function tryFromEth(uint256 _orderId) public returns(string memory){
        try this.fromEthNoFee(_orderId) returns(bool) {
            return "fromEthNoFee";
        }catch {
            return "";
        }

        try this.fromEthOnFee(_orderId) returns(bool) {
            return "fromEthOnFee";
        }catch {
            return "";
        }
    }

    function tryToEth(uint256 _orderId) public returns(string memory){
        try this.toEthNoFee(_orderId) returns(bool) {
            return "toEthNoFee";
        }catch {
            return "";
        }

        try this.toEthOnFee(_orderId) returns(bool) {
            return "toEthOnFee";
        }catch {
            return "";
        }
    }

    function  tryTokenToToken(uint256 _orderId) public returns(string memory){
        try this.tokenToTokenNoFee(_orderId) returns(bool) {
            return "tokenToTokenNoFee";
        }catch {
            return "";
        }

        try this.tokenToTokenOnFee(_orderId) returns(bool) {
            return "tokenToTokenOnFee";
        }catch {
            return "";
        }
    }
    

}