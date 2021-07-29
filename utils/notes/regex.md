# Small tidbits of useful regex info

* Match all strings not containing the specified word(s):
    - `^(.(?!(node_modules|vendor)))*$`
        + Match every character, from beginning to end, that doesn't have (word1|word2) in front of it.
        + Likely slow, but not any slower than `str.includes(word1) || str.includes(word2)`.
* Similarly, match all strings not containing the extension(s):
    - `\.(?!([tj]sx?))[^.]+$`
        + Same as above, except specifying to look only from last period to the end of the string.
