
LGA data is sourced from ABS LGA csv files, sourced from
http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1270.0.55.003July%202011?OpenDocument

ABS provides 1 LGA file per state e.g. LGA_2011_<state>.csv, with one record per
ABS Mesh Block (i.e. multiple records per LGA).

lga_clean processes the ABS csv data, skipping the headers, and spitting
out one record per LGA, and parsing the LGA composite name field into
separate name and LGA type fields.

Usage: `./lga_clean LGA_2011_*.csv`

