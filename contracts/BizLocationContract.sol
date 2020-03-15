pragma solidity ^0.5.14;

contract BizLocationContract {
    event bizLocationEvent(uint256 gln);

    struct Address {
        string streetAddressOne;
        string streetAddressTwo;
        string poBoxNumber;
        string city;
        string postalCode;
        string state;
        string countryCode;
    }

    struct bizLocationDetail {
        // Global Location Number, uniquely identifying a bizLocation worldwide
        uint256 gln;
        string bizLocationName;
        string bizLocationDescription;
        // active true or false
        bool bizLocationActive;
        // whether the bizLocation commissions tradeItems, i.e. is the originator of the raw tradeItem as
        // opposed to a processing bizLocation. A farm would be an example.
        bool tradeItemCommission;
        Address bizLocationAddress;
    }

    mapping(uint256 => bizLocationDetail) facilities;

    function createBizLocation(
        uint256 gln,
        string memory bizLocationName,
        string memory bizLocationDescription,
        bool bizLocationActive,
        bool tradeItemCommission,
        string memory streetAddressOne
    ) public {
        require(
            bizLocationActive == true,
            "Assets can only be created at facilities that commission raw tradeItems"
        );
        facilities[gln] = bizLocationDetail(
            gln,
            bizLocationName,
            bizLocationDescription,
            bizLocationActive,
            tradeItemCommission,
            Address(streetAddressOne, "", "", "", "", "", "")
        );
        emit bizLocationEvent(gln);
    }

    function get(uint256 gln)
        public
        view
        returns (
            string memory bizLocationName,
            string memory bizLocationDescription,
            bool bizLocationActive,
            bool tradeItemCommission,
            string memory streetAddressOne
        )
    {
        bizLocationDetail storage fd = facilities[gln];
        return (
            fd.bizLocationName,
            fd.bizLocationDescription,
            fd.bizLocationActive,
            fd.tradeItemCommission,
            fd.bizLocationAddress.streetAddressOne
        );
    }
}
