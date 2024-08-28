# Maturity Levels for CLIF

CLIF is an evolving format, and some parts of the format are more mature than others. Specifically, the ER model and the tables have two different maturity levels.

## Maturity Level for CLIF Entity-Relationship Model

- ![Experimental](https://img.shields.io/badge/Maturity-Experimental-red) **Experimental**: Majority of critical illness and hospital course not represented in ER model, expect frequent breaking changes.
- ![Beta](https://img.shields.io/badge/Maturity-Beta-yellow) **Beta**: ER model complete and breaking changes to the existing structure unlikely. Actively seeking feedback about new tables to add to the ER model to fully capture critical illness.
- ![Stable](https://img.shields.io/badge/Maturity-Stable-brightgreen) **Stable**: Tested and recommended for general use. EHR data not currently represented in CLIF outside the scope of the format.
- ![Mature](https://img.shields.io/badge/Maturity-Mature-blue) **Mature**: Widely adopted across majority of consoritium sites with majority of tables in stable or mature (see maturity levels for CLIF Tables). ER model very stable.
- ![Deprecated](https://img.shields.io/badge/Maturity-Deprecated-lightgrey) **Deprecated**: No longer maintained.

The entity-relationship model for this project is currently at the ![Beta](https://img.shields.io/badge/Maturity-Beta-yellow) **Beta** level. ER model complete and breaking changes to the existing structure unlikely. Actively seeking feedback about new tables to add to the ER model.

## Maturity Levels for CLIF Tables

There are two critical maturity elements for each CLIF table: 1) field structure and 2) Common ICU data Element development.

- ![Concept](https://img.shields.io/badge/Maturity-Concept-orange) **Concept**: Placeholder for future CLIF table. Majority of table structure and CDE elements incomplete. Expect breaking changes.
- ![Beta](https://img.shields.io/badge/Maturity-Beta-yellow) **Beta**: Table structure and field names complete, but not fully tested. CDE for category variables underdevelopment. Actively seeking feedback. 
- ![Stable](https://img.shields.io/badge/Maturity-Stable-brightgreen) **Stable**: Tested and recommended for general use. CDE stable with permissible values for all category variables precisely defined and locked. Fully implemented at at least two consortium sites
- ![Mature](https://img.shields.io/badge/Maturity-Mature-blue) **Mature**: Adopted across a majority of the CLIF consortium sites and very stable.
- ![Deprecated](https://img.shields.io/badge/Maturity-Deprecated-lightgrey) **Deprecated**: No longer maintained.
