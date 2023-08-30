// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SmartPointer} from "src/smart-pointer/SmartPointer.sol";
import {Primitive} from "src/primitive/Primitive.sol";

library EnumerableSet {
    struct Set {
        SmartPointer[] values;
        // need to call `hash` on the key before using it
        mapping(Primitive => uint256) indices;
    }

    function add(Set storage self, SmartPointer value) internal returns (bool) {
        self.values.push(value);

        // store the index + 1 so that 0 is not a valid index
        Primitive key = value.hash();
        self.indices[key] = order(self);
        return true;
    }

    function remove(
        Set storage self,
        SmartPointer value
    ) internal returns (bool) {
        Primitive key = value.hash();
        uint256 idx = self.indices[key];

        // the `indicies` maping is 1-indexed but the array is 0-indexed
        unchecked {
            if (idx-- == 0) {
                return false;
            }
        }

        uint256 lastIndex = order(self) - 1;
        if (idx != lastIndex) {
            SmartPointer lastValue = self.values[lastIndex];

            self.values[idx] = self.values[lastIndex];
            self.indices[lastValue.hash()] = idx;
        }

        self.values.pop();
        delete self.indices[key];
        return true;
    }

    //////////////////////////////////////////////////////////
    /////// View Functions
    //////////////////////////////////////////////////////////

    function equals(
        EnumerableSet.Set storage self,
        SmartPointer[] memory other
    ) internal view returns (bool) {
        if (order(self) != other.length) {
            return false;
        }

        uint256[] memory bitmap = new uint256[](other.length / 256 + 1);

        for (uint256 i = 0; i < other.length; i++) {
            uint256 idx = self.indices[other[i].hash()];

            if (idx == 0) {
                return false;
            }

            if (priv_bm_get(bitmap, idx)) {
                return false;
            }

            priv_bm_set(bitmap, idx);
        }

        return true;
    }

    function contains(
        Set storage self,
        SmartPointer value
    ) internal view returns (bool) {
        return self.indices[value.hash()] != 0;
    }

    function order(Set storage self) internal view returns (uint256) {
        return self.values.length;
    }

    // todo does solidity handle this yet?
    function values(
        Set storage self
    ) internal view returns (SmartPointer[] memory) {
        SmartPointer[] memory result = new SmartPointer[](order(self));

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = self.values[i];
        }

        return result;
    }

    //////////////////////////////////////////////////////////
    /////// Private Functions
    //////////////////////////////////////////////////////////

    function priv_bm_set(uint256[] memory bitmap, uint256 index) private pure {
        unchecked {
            bitmap[index / 256] |= (1 << (index % 256));
        }
    }

    function priv_bm_get(
        uint256[] memory bitmap,
        uint256 index
    ) private pure returns (bool) {
        unchecked {
            return (bitmap[index / 256] & (1 << (index % 256))) != 0;
        }
    }
}
