-- Business definition of a reporting week: ISO-8601 week number.
-- NOTE: reporting expects Monday as the first day of the week regardless of
-- the session DATEFIRST setting, hence the explicit ISO_WEEK datepart.
CREATE FUNCTION [dbo].[fn_SalesWeek]
(
    @SalesDate DATE
)
RETURNS INT
AS
BEGIN
    IF @SalesDate IS NULL
        RETURN NULL;

    RETURN DATEPART(ISO_WEEK, @SalesDate);
END
