pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IERC20.sol";
import "./DecimalMath.sol";

contract Exchange is Ownable {

    using SafeMath for uint256;

    uint256 private _conversionRate;
    IERC20 private _denominatedToken;
    IERC20 private _token;

    mapping(address => mapping(address => uint256)) internal rates;

    event ConversionRateChanged(uint256 _oldConversionRate, uint256 _newConversionRate);
    event TokenExchanged(uint256 _givenAmount, uint256 _exchangedAmount, address _reciever);

    /**
     * @notice Constructor 
     * @param conversionRate Rate that is used to exchange the token with denominated token
     * @param token Address of the ERC20 compliance token which needs to be converted with denominated token
     * @param denominatedToken Address of the ERC20 compliance token which act as the base currency
     */
    constructor(uint256 conversionRate, address token, address denominatedToken) public {
        require(token != address(0) && denominatedToken != address(0), "Wrong address");
        require(conversionRate > 0, "Invalid rate");
        _token = IERC20(token);
        _denominatedToken = IERC20(denominatedToken);
        _conversionRate = conversionRate;
    }

    /**
     * @notice returns the current conversion rate
     */
    function conversionRate() public view returns(uint256) {
        return _conversionRate;
    }   

    /**
     * @notice change the conversion rate
     * @dev `_newRate` should be a multiple of 10 ** 16
     * @param _newRate New conversion rate 
     */
    function changeConversionRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Invalid rate");
        emit ConversionRateChanged(_conversionRate, _newRate);
        _conversionRate = _newRate;
    }

    /**
     * @notice Use to exchange to token
     * @dev It will convert the X amount of given token(tokenAddress) to the Y amount of corresponding denominated token
     * If exchange hold Y amounts of token then it will directly send it to the msg.sender otherwise new tokens get minted
     * and transferred to the msg.sender.
     * @param amount Amount of tokens that needs to be exchanged
     * @param tokenAddress Act as the primaryToken 
     */
    function exchange(uint256 amount, address tokenAddress) external {
        require(amount != 0, "amount should not be 0");
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount),
            "unsufficient allowance"
        );
        uint256 exchangeAmount = getConvertedAmount(amount, tokenAddress);
        require(exchangeAmount > 0);
        if (tokenAddress == address(_token))
            _sendTokens(exchangeAmount, _token);
        else
            _sendTokens(exchangeAmount, _denominatedToken);
        emit TokenExchanged(amount, exchangeAmount, msg.sender);  
    }

    function getConvertedAmount(uint256 amount, address token) public view returns(uint256) {
        if (token == address(_token))
            return DecimalMath.mul(amount, _conversionRate);
        else if (token == address(_denominatedToken)) {
            return DecimalMath.div(amount, _conversionRate);
        } else
            return 0;
    } 

    function _sendTokens(uint256 exchangeAmount, IERC20 token) internal {
        if (token.balanceOf(address(this)) >= exchangeAmount)
                require(token.transfer(msg.sender, exchangeAmount));
        else {
            uint256 currentBalance = token.balanceOf(address(this));
            uint256 remainingBalance = exchangeAmount.sub(currentBalance);
            require(token.transfer(msg.sender, currentBalance));
            require(token.mint(msg.sender, remainingBalance));
        }
    }


}