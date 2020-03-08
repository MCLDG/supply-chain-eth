pragma solidity ^0.5.14;

contract BusinessLocation {
    event BusinessLocationEvent(uint256 gln);

    struct Address {
        string streetAddressOne;
        string streetAddressTwo;
        string poBoxNumber;
        string city;
        string postalCode;
        string state;
        string countryCode;
    }

    struct BusinessLocationDetail {
        // Global Location Number, uniquely identifying a businessLocation worldwide
        uint256 gln;
        string businessLocationName;
        string businessLocationDescription;
        // active true or false
        bool businessLocationActive;
        // whether the businessLocation commissions assets, i.e. is the originator of the raw asset as
        // opposed to a processing businessLocation. A farm would be an example.
        bool assetCommission;
        Address businessLocationAddress;
    }

    mapping(uint256 => BusinessLocationDetail) facilities;

    function createBusinessLocation(
        uint256 gln,
        string memory businessLocationName,
        string memory businessLocationDescription,
        bool businessLocationActive,
        bool assetCommission,
        string memory streetAddressOne
    ) public {
        require(
            businessLocationActive == true,
            "Assets can only be created at facilities that produce/commission raw assets"
        );
        facilities[gln] = BusinessLocationDetail(
            gln,
            businessLocationName,
            businessLocationDescription,
            businessLocationActive,
            assetCommission,
            Address(streetAddressOne, "", "", "", "", "", "")
        );
        emit BusinessLocationEvent(gln);
    }

    function get(uint256 gln)
        public
        view
        returns (
            string memory businessLocationName,
            string memory businessLocationDescription,
            bool businessLocationActive,
            bool assetCommission,
            string memory streetAddressOne
        )
    {
        BusinessLocationDetail storage fd = facilities[gln];
        return (
            fd.businessLocationName,
            fd.businessLocationDescription,
            fd.businessLocationActive,
            fd.assetCommission,
            fd.businessLocationAddress.streetAddressOne
        );
    }
}
