# Error code

## Structure

| Digit            | Meaning     |
| ---------------- | ----------- |
| first and second | script code |
| third            | part        |
| fourth and five  | error code  |

## Script code

| Code | Script           |
| ---- | ---------------- |
| 00   | gif.ps1          |
| 01   | MergeInto.ps1    |
| 02   | DeleteBranch.ps1 |

## Part

| Code | Part         |
| ---- | ------------ |
| 0    | Init & Check |
| 1    | Main Task    |
| 2    | Clean        |

## Table

<!-- markdownlint-disable -->

| Code  | Script           | Part         | Meaning                                                            |
| ----- | ---------------- | ------------ | ------------------------------------------------------------------ |
| 00001 | gif.ps1          | Init & Check | Git version unsatisfied (Require 2.23+)                            |
| 00101 | gif.ps1          | Main Task    | No such gif command                                                |
| 01001 | MergeInto.ps1    | Init & Check | Target branch cannot be null or empty                              |
| 01002 | MergeInto.ps1    | Init & Check | You are not in a git repository                                    |
| 01003 | MergeInto.ps1    | Init & Check | Your repository has no branch now                                  |
| 01004 | MergeInto.ps1    | Init & Check | Target branch does not exist locally                               |
| 01005 | MergeInto.ps1    | Init & Check | You don't need merge branch into itself                            |
| 01006 | MergeInto.ps1    | Init & Check | Detected multiple remotes and could not find remote named "origin" |
| 01201 | MergeInto.ps1    | Clean        | Other error                                                        |
| 01202 | MergeInto.ps1    | Clean        | Merge conflict                                                     |
| 02001 | DeleteBranch.ps1 | Init & Check | You are not in a git repository                                    |
| 02002 | DeleteBranch.ps1 | Init & Check | Your repository has no branch now                                  |
| 02003 | DeleteBranch.ps1 | Init & Check | Detected multiple remotes and could not find remote named "origin" |
| 02201 | DeleteBranch.ps1 | Clean        | Other error                                                        |

<!-- markdownlint-enable -->
