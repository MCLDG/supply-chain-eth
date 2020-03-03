pragma solidity ^0.5.14;

contract Facility {

    event FacilityEvent(uint256 gln);

    struct PhysicalAddress {
        string streetAddressOne;
        string streetAddressTwo;
        string poBoxNumber;
        string city;
        string postalCode;
        string state;
        string countryCode;
    }

    struct FacilityDetail {
        // Global Location Number, uniquely identifying a facility worldwide
        uint256 gln;
        string facilityName;
        string facilityDescription;
        string facilityStatus;
        PhysicalAddress facilityAddress;
    }

    mapping (uint256 => FacilityDetail) facilities;

    function createFacility(
        uint256 gln,
        string memory facilityName,
        string memory facilityDescription,
        string memory facilityStatus,
        string memory streetAddressOne
    ) public {
        facilities[gln] = FacilityDetail(
                gln,
                facilityName,
                facilityDescription,
                facilityStatus,
                PhysicalAddress(streetAddressOne, "", "", "", "", "", "")
        );
        emit FacilityEvent(gln);
    }

    function get(uint256 gln) public view returns (
        string memory facilityName,
        string memory facilityDescription,
        string memory facilityStatus,
        string memory streetAddressOne
    ) {
        FacilityDetail storage fd = facilities[gln];
        return (fd.facilityName, fd.facilityDescription, fd.facilityStatus, fd.facilityAddress.streetAddressOne);
    }
}
