// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SmartPointer} from "src/smart-pointer/SmartPointer.sol";

library EnumerableSet {
    struct Map {
        SmartPointer[] values;
        // need to call `hash` on the key before using it
        mapping(bytes32 => uint256) indices;
    }

    function add(Map storage self, SmartPointer value) internal returns (bool) {
        self.values.push(value);

        // store the index + 1 so that 0 is not a valid index
        bytes32 key = value.hash().asBytes32();
        self.indices[key] = self.values.length;
        return true;
    }

    function remove(
        Map storage self,
        SmartPointer value
    ) internal returns (bool) {
        bytes32 key = value.hash().asBytes32();
        uint256 idx = self.indices[key];

        // the `indicies` mapping is 1-indexed but the array is 0-indexed
        unchecked {
            if (idx-- == 0) {
                return false;
            }
        }

        uint256 lastIndex = self.values.length - 1;
        if (idx != lastIndex) {
            SmartPointer lastValue = self.values[lastIndex];

            self.values[idx] = self.values[lastIndex];
            self.indices[lastValue.hash().asBytes32()] = idx;
        }

        self.values.pop();
        delete self.indices[key];
        return true;
    }

    function contains(
        Map storage self,
        SmartPointer value
    ) internal view returns (bool) {
        return self.indices[value.hash().asBytes32()] != 0;
    }

    function order(Map storage self) internal view returns (uint256) {
        return self.values.length;
    }

    // todo does solidity handle this?
    function values(
        Map storage self
    ) internal view returns (SmartPointer[] memory) {
        SmartPointer[] memory result = new SmartPointer[](
            self.values.length - 1
        );

        for (uint256 i = 0; i < self.values.length; i++) {
            result[i] = self.values[i];
        }
    }
}
