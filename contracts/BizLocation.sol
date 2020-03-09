pragma solidity ^0.5.14;

contract BizLocation {
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
        // whether the bizLocation commissions assets, i.e. is the originator of the raw asset as
        // opposed to a processing bizLocation. A farm would be an example.
        bool assetCommission;
        Address bizLocationAddress;
    }

    mapping(uint256 => bizLocationDetail) facilities;

    function createBizLocation(
        uint256 gln,
        string memory bizLocationName,
        string memory bizLocationDescription,
        bool bizLocationActive,
        bool assetCommission,
        string memory streetAddressOne
    ) public {
        require(
            bizLocationActive == true,
            "Assets can only be created at facilities that produce/commission raw assets"
        );
        facilities[gln] = bizLocationDetail(
            gln,
            bizLocationName,
            bizLocationDescription,
            bizLocationActive,
            assetCommission,
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
            bool assetCommission,
            string memory streetAddressOne
        )
    {
        bizLocationDetail storage fd = facilities[gln];
        return (
            fd.bizLocationName,
            fd.bizLocationDescription,
            fd.bizLocationActive,
            fd.assetCommission,
            fd.bizLocationAddress.streetAddressOne
        );
    }
}
