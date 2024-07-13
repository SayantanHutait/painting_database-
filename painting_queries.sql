select * from museum
select * from artist
select * from work
select * from canvas_size
select * from product_size
select * from subject
select * from image_link
select * from museum_hours
-- Fetch all the paintings which are not displayed on any museums?

select name from work where museum_id is NULL

--Are there museuems without any paintings?
select m.name from museum m LEFT join work w
ON m.museum_id = w.museum_id
where w.museum_id is NULL

/*select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id)*/

--How many paintings have an asking price of more than their regular price? 
select * from product_size
	where sale_price > regular_price

--Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size
	where sale_price < regular_price*0.5

--Which canva size costs the most?


select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id::text=ps.size_id
	where ps.rnk=1;

--Delete duplicate records from work, product_size, subject and image_link tables

delete from work
where ctid not in (select min(ctid) from work group by work_id)

delete from product_size 
where ctid not in (select min(ctid) from product_size group by work_id, size_id );


--Identify the museums with invalid city information in the given dataset
	select * from museum 
	where city ~ '^[0-9]'

--Fetch the top 10 most famous painting subject
select subject, count(work_id) from subject
group by subject 
order by count(work_id) DESC LIMIT 10

/*select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;
*/

--Identify the museums which are open on both Sunday and Monday. Display museum name, city.

/*SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh1 ON m.museum_id = mh1.museum_id
JOIN museum_hours mh2 ON m.museum_id = mh2.museum_id
WHERE mh1.day = 'Sunday'
  AND mh2.day = 'Monday';*/


SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh ON m.museum_id = mh.museum_id
WHERE mh.day IN ('Sunday', 'Monday')
GROUP BY m.name, m.city
HAVING COUNT(DISTINCT mh.day) = 2;


--How many museums are open every single day?

select count(museum_id) from (
	select museum_id,count(1) from museum_hours 
	group by museum_id
	having count(1) = 7
)

/*SELECT COUNT(1)
FROM (
    SELECT museum_id, COUNT(1)
    FROM museum_hours
    GROUP BY museum_id
    HAVING COUNT(1) = 7
) subquery;*/

--Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

select m.name, x.no_of_paintings from (
	select m.museum_id,count(1) as no_of_paintings from
	museum m join work w on m.museum_id = w.museum_id
	group by m.museum_id) x join museum m on m.museum_id= x.museum_id
order by x.no_of_paintings DESC
limit 5

/*select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;*/

--Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select a.full_name, x.no_of_painintgs from(
	select a.artist_id, count(1) as no_of_painintgs from
	artist a join work w on a.artist_id = w.artist_id
	group by a.artist_id
	) x join artist a on a.artist_id = x.artist_id
order by x.no_of_painintgs DESC
LIMIT 5

/*select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;*/

--Display the 3 least popular canva sizes

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id::text = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;



--Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

select name, duration from (select m.name as name,mh.open,mh.close,to_timestamp(close,'HH:MI PM')-to_timestamp(open,'HH:MI PM') as Duration ,
 rank() over (order by (to_timestamp(close,'HH:MI PM') - to_timestamp(open,'HH:MI AM')) desc) as rnk
from museum_hours mh
join museum m on m.museum_id=mh.museum_id) x
where x.rnk = 1

--Which museum has the most no of most popular painting style?

with pop_style as(
	select style, rank() over(order by count(1) DESC) as rnk
	from work
	group by style
)

SELECT m.name AS museum_name, w.style, COUNT(*) AS no_of_paintings
FROM work w
JOIN museum m ON m.museum_id = w.museum_id
JOIN pop_style ps ON ps.style = w.style
GROUP BY m.name, w.style
ORDER BY no_of_paintings DESC
LIMIT 1

--Identify the artists whose paintings are displayed in multiple countries

WITH cte AS (
    SELECT DISTINCT a.full_name AS artist, m.country
    FROM work w
    JOIN artist a ON a.artist_id = w.artist_id
    JOIN museum m ON m.museum_id = w.museum_id
)
SELECT artist, COUNT(DISTINCT country) AS no_of_countries
FROM cte
GROUP BY artist
HAVING COUNT(DISTINCT country) > 1
ORDER BY no_of_countries DESC;

--Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.

WITH cte_country AS (
    SELECT country, COUNT(1) AS country_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rank
    FROM museum
    GROUP BY country
),
cte_city AS (
    SELECT city, COUNT(1) AS city_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rank
    FROM museum
    GROUP BY city
)
SELECT
    STRING_AGG(DISTINCT country.country, ', ') AS top_countries,
    STRING_AGG(DISTINCT city.city, ', ') AS top_cities
FROM cte_country country
CROSS JOIN cte_city city
WHERE country.country_rank = 1
  AND city.city_rank = 1;






