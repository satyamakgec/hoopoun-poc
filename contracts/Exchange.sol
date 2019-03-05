pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IERC20.sol";
import "./DecimalMath.sol";

contract Exchange is Ownable {

    using SafeMath for uint256;

    IERC20 private _denominatedToken;

    mapping(address => mapping(address => uint256)) internal rates;

    event ConversionRateChanged(uint256 _oldConversionRate, uint256 _newConversionRate, address _token);
    event TokenExchanged(uint256 _givenAmount, uint256 _exchangedAmount, address _reciever, address _denominatedToken);

    /**
     * @notice Constructor 
     * @param denominatedToken Address of the ERC20 compliance token which act as the base currency
     */
    constructor(address denominatedToken) public {
        require(denominatedToken != address(0), "Wrong address");
        _denominatedToken = IERC20(denominatedToken);
    }

    /**
     * @notice returns the current conversion rate
     */
    function conversionRate(address _token) public view returns(uint256) {
        return rates[address(_denominatedToken)][_token];
    }

    /**
     * @notice return the token symbol of the denominated currency
     */
    function denominatedToken() external view returns(string memory) {
        return _denominatedToken.symbol();
    }   

    /**
     * @notice change the conversion rate
     * @dev `_newRate` should be a multiple of 10 ** 16
     * @param _newRate New conversion rate (It will depict how many token can be bought using the 1 denominated token (HPC))
     * @param _token Address of the token which will be converted in to denominated token
     */
    function changeConversionRate(uint256 _newRate, address _token) external onlyOwner {
        require(_newRate > 0, "Invalid rate");
        require(_token != address(0), "Invalid token address");
        emit ConversionRateChanged(rates[address(_denominatedToken)][_token], _newRate, _token);
        rates[address(_denominatedToken)][_token] = _newRate;
    }

    /**
     * @notice Use to exchange to token
     * @dev It will convert the X amount of given token(tokenAddress) to the Y amount of corresponding denominated address (_denominatedAddress)
     * If exchange hold Y amounts of token then it will directly send it to the msg.sender otherwise new tokens get minted
     * and transferred to the msg.sender.
     * @param _amount Amount of tokens that needs to be exchanged
     * @param _tokenAddress Act as the primaryToken 
     * @param _denominatedAddress Denominated token address
     */
    function exchange(uint256 _amount, address _tokenAddress, address _denominatedAddress) external {
        require(_amount != 0, "amount should not be 0");
        require(
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
            "unsufficient allowance"
        );
        uint256 exchangeAmount = getConvertedAmount(_amount, _tokenAddress, _denominatedAddress);
        require(exchangeAmount > 0, "Invalid amount");
        if (_denominatedAddress != address(0))
            _sendTokens(exchangeAmount, IERC20(_denominatedAddress));
        else
            _sendTokens(exchangeAmount, _denominatedToken);
        emit TokenExchanged(_amount, exchangeAmount, msg.sender, (_denominatedAddress != address(0) ? address(_denominatedToken): _denominatedAddress));  
    }

    function getConvertedAmount(uint256 _amount, address _token, address _denominatedAddress) public view returns(uint256) {
        if (_denominatedAddress == address(0) && _token != address(_denominatedToken))
            return DecimalMath.div(_amount, rates[address(_denominatedToken)][_token]);

        else if (_token == address(_denominatedToken) && _denominatedAddress != address(0))
            return DecimalMath.mul(_amount, rates[address(_denominatedToken)][_denominatedAddress]);

        else {
            // Amount for denominated token
            uint256 _denominatedAmount = DecimalMath.div(_amount, rates[address(_denominatedToken)][_token]);
            return DecimalMath.mul(_denominatedAmount, rates[address(_denominatedToken)][_denominatedAddress]);
        }
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