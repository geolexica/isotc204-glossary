[Home](../index.md) · [Entity Terms](groups/Entity Terms.md) · ITS application

# ITS application

requirements for an [ITS service](ITS service.md) that involves an association of two or more complementary [ITS-S application processes](ITS-S application process.md)

Clause: 3.2.8.1

Note 1 to entry: An ITS application can also involve associations with nodes that are not ITS stations.

Note 2 to entry: This is a clarification of the ISO 21217:2020 definition.

History note: 2025: Revised to be "requirements for" rather than "realization of"
History note: Introduced in ISO/TS 14812:2022

## Relationships for ITS application

| Property | Constraint |
| --- | --- |
| involves | min 2 owl::Thing |
| realizationOf | some itsService |

## Specializations of ITS application

| Class | Description |
| --- | --- |
| [Personal ITS application](Personal ITS application.md) | [ITS application](ITS application.md) for a single [traveller](traveller.md) |

---

[Comment on this page](https://github.com/ISO-TC204/iso14812/issues/new?template=page-feedback.yml)
