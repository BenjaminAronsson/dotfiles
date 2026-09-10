// Fuzzy subsequence matching for the launcher — no dependencies.
// Scores like rofi/fzf: every query char must appear in order; consecutive
// matches and matches at word boundaries score higher. Case-insensitive.
//
// score("br", "Brave Browser")  -> high (word starts)
// score("ff", "Firefox")        -> medium (consecutive)
// score("xyz", "Firefox")       -> -1 (no match)

// Returns -1 on no match, otherwise a score (higher is better).
function fuzzyScore(query, text) {
    if (!query || query.length === 0)
        return 0;
    if (!text || text.length === 0)
        return -1;

    query = query.toLowerCase();
    text = text.toLowerCase();

    let score = 0;
    let qi = 0;               // query index
    let lastMatch = -2;       // index of previous matched char in text
    let firstMatch = -1;

    for (let ti = 0; ti < text.length && qi < query.length; ti++) {
        if (text[ti] !== query[qi])
            continue;

        if (firstMatch === -1)
            firstMatch = ti;

        // Consecutive match bonus
        if (ti === lastMatch + 1)
            score += 5;

        // Word-start bonus (start of string or after a separator)
        if (ti === 0 || text[ti - 1] === " " || text[ti - 1] === "-" ||
            text[ti - 1] === "_" || text[ti - 1] === ".")
            score += 10;

        score += 1;
        lastMatch = ti;
        qi++;
    }

    if (qi < query.length)
        return -1; // not all query chars matched

    // Prefer earlier and tighter matches
    score -= firstMatch;
    score -= (text.length - query.length) * 0.1;

    return score;
}

// Best score across several fields of a candidate. `fields` is an array of
// [text, weight] pairs; the max weighted score wins, or -1 if none match.
function scoreFields(query, fields) {
    let best = -1;
    for (let i = 0; i < fields.length; i++) {
        const s = fuzzyScore(query, fields[i][0]);
        if (s >= 0) {
            const weighted = s * fields[i][1];
            if (weighted > best)
                best = weighted;
        }
    }
    return best;
}
