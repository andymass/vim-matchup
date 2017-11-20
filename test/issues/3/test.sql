drop function if exists dummy;

create or replace function dummy()
returns setof text as
$$
begin
	return next 'something';
	return;
end
$$ language 'plpgsql';

CREATE FUNCTION dbo.median (@score int)
RETURNS NUMERIC(20,2)
AS BEGIN
DECLARE @MedianScore as NUMERIC(20,2);
SELECT @MedianScore=
(
 (SELECT MAX(@score) FROM
   (SELECT TOP 50 PERCENT Score FROM t ORDER BY Score) AS BottomHalf)
 +
 (SELECT MIN(@score) FROM
   (SELECT TOP 50 PERCENT Score FROM t ORDER BY Score DESC) AS TopHalf)
) / 2 ;
RETURN(@MedianScore);
END;

