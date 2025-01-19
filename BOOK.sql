
CREATE TABLE book(
	book_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(50),
	author VARCHAR(30),
	amount DECIMAL(8,2),
	price INT);

INSERT INTO book (title, author, price, amount)
VALUES ('Белая гвардия', 'Булгаков М.А.','540.50', '5'), ('Идиот', 'Достоевский Ф.М.','460.00', '10'), ('Братья Карамазовы', 'Достоевский Ф.М.','799.01', '2');
SELECT * from book;

--Наприкінці року ціну кожної книги на складі перераховують – знижують її на 30%.
SELECT title, author, amount, ROUND((price*0.7),2) AS new_price FROM book

--Під час аналізу продажів книг з'ясувалося, що найбільшою популярністю користуються книги Михайла Булгакова, на другому місці книги Сергія Єсеніна. 
--Тому вирішили підняти ціну книг Булгакова на 10%, а ціну книг Єсеніна - на 5%.
SELECT author, title, 
	ROUND(IF(author='Булгаков М.А.', price*1.1,IF(author='Есенин', price*1.05,price)),2) AS new_price

--Автор, ціна та кількість усіх книг, ціна яких менша за 500 або більше 600, а вартість всіх примірників цих книг більша або дорівнює 5000.
SELECT author, price, amount FROM book
WHERE (price<500 OR price>600) and amount*price>=5000;

--Назва та авторка книг, ціни яких належать інтервалу від 540.50 до 800 (включаючи межі), а кількість або 2, або 3, або 5, або 7.
SELECT title, author, price FROM book
WHERE (price between 540.5 and 800) and amount in(2,3,5,7);
ORDER BY 2, 3

--Назва та автора тих книг, назва яких складається із двох і більше слів, а ініціали автора містять літеру «С».
SELECT title, author FROM book
WHERE title LIKE "_% %" AND (author LIKE "%_.C.%" OR LIKE "%C._.%")
ORDER BY title

--Кількість різних книг і кількість екземплярів книг кожного автора, що зберігаються на складі.
SELECT author AS '', COUNT(DISTINCT(amount)) AS 'Pізнi_книги', SUM(amount) AS 'кількість'
	FROM book
GROUP BY author;

--Прізвище та ініціали автора, мінімальна, максимальна та середня ціна книг кожного автора.
SELECT author, MIN(price) AS 'мінімальна_ціна', MAX(price) AS 'максимальна_ціна', AVG(price) AS 'середня_ціна'
	FROM book
GROUP BY author;

--Сумарна вартість книг S (ім'я стовпця Вартість), податок на додану вартість для отриманих сум (ім'я стовпця ПДВ), 
--який включений у вартість та становить 18% (k=18), а також вартість книг (Вартість_без_ПДВ) без нього.
SELECT author, SUM(price*amount) AS 'Вартість', ROUND(SUM(price*amount*0.18/(1+0.18)),2) AS 'ПДВ',
	  ROUND(SUM(price*amount)/1.18),2) AS 'Вартість_без_ПДВ'
	  FROM book
GROUP BY author;

--Вартість всіх екземплярів кожного автора без урахування книг «Ідіот» та «Біла гвардія» із сумарною вартістю книг (без урахування книг «Ідіот» та «Біла гвардія») понад 5000.
SELECT author, SUM(price*amount) as 'Сумарна_вартість' FROM book
WHERE author<>'Ідіот' OR author<>'Біла гвардія'
GROUP BY author
HAVING SUM(price*amount)>5000
ORDER BY 3 DESC;

--Aвтор, назва та ціна книг, ціни яких перевищують мінімальну ціну книги на складі не більше ніж на 150 у відсортованому за зростанням ціни.
SELECT author, title, price FROM book
WHERE ABS(price-(SELECT MIN(price) FROM book))<=150
ORDER BY price ASC;

--Автор, назва та ціна тих книг, кількість екземплярів яких у таблиці book не дублюється.
SELECT author, title, amount FROM book
WHERE amount in(SELECT amount FROM book GROUP BY amount HAVING COUNT(amount)=1);

--Aвтор, назва та ціна тих книг, ціна яких менша за найбільшу з мінімальних цін, обчислених для кожного автора.
SELECT author, title, amount FROM book
WHERE price<ANY(SELECT MIN(price) FROM book GROUP BY author);

--Кількість та яких екземплярів книг потрібно замовити постачальникам, щоб на складі стала однакова кількість екземплярів кожної книги, 
--що дорівнює значенню найбільшої кількості екземплярів однієї книги на складі.
SELECT author, title, ((SELECT MAX(amount) FROM book)-amount) AS 'Заказ' FROM book
WHERE amount not in(SELECT MAX(amount) FROM book);

--Відсоток вигоди
SELECT *, ROUND((price*amount)/(SELECT SUM(price*amount) FROM book),2)*100 AS 'Відсоток_вигоди' 
FROM book
ORDER BY Відсоток_вигоди DESC;
	  
--Занести з таблиці supply в таблицю book лише книжки, авторів яких немає у book.
INSERT INTO book(title, author, price, amount)
SELECT title, author, price, amount FROM supply
WHERE author not in(SELECT author FROM book);

--Коригування значення для покупця в стовпці буде таким чином, щоб воно не перевищувало кількість екземплярів книг, зазначених у стовпці amount.
--А ціну тих книг, що їх покупець не замовляв, знизив на 10%.
UPDATE book
SET buy=IF(BUY>amount, amount, buy),
    price=IF(buy=0, price*0.9, price);

--Для тих книг у таблиці book , які є в таблиці supply, не тільки збільшити їх кількість в таблиці book ( збільшити їх кількість на значення стовпця amount таблиці supply),
--але й перерахувати їхню ціну.
UPDATE book, supply
SET book.amount=book.amount+supply.amount,
    book.price=(book.price+supply.price)/2
WHERE book.author+supply.author AND book.title+supply.title;
	  
--Видалити з таблиці supply книги тих авторів, загальна кількість екземплярів книг яких у таблиці book перевищує 10.
DELETE FROM supply
WHERE author in(SELECT author FROM book HAVING SUM(amount)>10);

--Таблицю замовлення (ordering), ключає авторів та назви книг, кількість екземплярів яких у таблиці book менша за середню кількість екземплярів книг у таблиці book.
CREATE TABLE ordering AS
SELECT author, title, (SELECT ROUND(AVG(amount)) FROM book) as amount 
	FROM book
WHERE amount<(SELECT ROUND(AVG(amount)) FROM book);

--Знижка 5% на найбільшу кількість екземплярів книг
UPDATE boook AS b1
SET b1.price=b1.price*0.95
WHERE b1.amount=(SELECT MAX(b2.amount) FROM (SELECT * FROM book) AS b2); 
    	
--Всі книги зі складу передали в магазин 
--(Заніс із таблиці supply в таблицю book тільки ті книги, назви яких відсутні в таблиці book, при цьому кількість цих книг у таблиці supply обнулив).
-- Три варіанти рішення
1. INSERT INTO book (title, author, price)
SELECT title, author, price from supply 
where (title, author) not in (SELECT title, author from  book);
UPDATE book, supply SET
    book.amount = supply.amount,
    supply.amount = 0
WHERE book.title = supply.title AND book.amount IS NULL;
SELECT * FROM book;
SELECT * FROM supply;

2. CREATE TABLE delivery AS
SELECT title, author, price, amount FROM supply WHERE title NOT IN (SELECT title FROM book);
UPDATE supply SET supply.amount=IF(supply.title=ANY(SELECT title FROM book), supply.amount, 0);
INSERT INTO book (title, author, price, amount) 
       SELECT * FROM delivery; 
SELECT * FROM book;
SELECT * FROM supply;

3. INSERT INTO book (title, author, price, amount)
SELECT title, author, price, -1 AS amount from supply
WHERE title not in(select title
                   from book); 
UPDATE book, supply SET
    book.amount = supply.amount,
    supply.amount = 0
WHERE book.title = supply.title AND book.amount = -1;
SELECT * FROM book;
SELECT * from supply
------------------------------------------------------------------------------------------------------ Complicating the table
CREATE TABLE book(
	book_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(50),
	author_id is not NULL,
	genre_id INT,
	price DECIMAL(8.2),
	amount INT,
	FOREIGN KEY(author_id) REFERENCES author (author_id) ON DELETE CASCADE,
	FOREIGN KEY(genre_id) REFERENCES genre (author_id) ON DELETE SET Null
	);
--Title, genre and price of books, the number of which is more than 8, sorted in descending order of price.
SELECT title, name_genre, price
FROM genre g INNER JOIN book b  ON g.genre_id=b.genre_id and book.amount>8
ORDER BY price DESC;

--All genres that are not represented in the books in stock.
SELECT name_genre
FROM genre g LEFT JOIN book b ON g.genre_id=b.genre_id
WHERE b.amount is Null;

--Each city will host an exhibition of books by each author during 2020. The date of the exhibition was chosen randomly.
SELECT name_city, name_author, (DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND()*365)DAY)) AS 'DATE'
FROM city, author
ORDER BY name_city DESC, DATE DESC;

--The number of copies of books by each author from the author table. The authors whose number of books is less than 10 are displayed, sorted by increasing number.
SELECT name_author, SUM(amount) as 'sum'
FROM author LEFT JOIN book USING(author_id)
GROUP BY name_author
HAVING sum<10 OR sum is Null
ORDER BY sum ASC;

--All authors who write in only one genre are listed in alphabetical order.
SELECT name_author
FROM author JOIN book USING(author_id)
            JOIN genre USING(genre_id)
GROUP BY name_author
HAVING COUNT(DISTINCT(name_genre))=1;

--Information about books written in the most popular genres, sorted alphabetically by book title.
SELECT title, name_author, name_genre, price, amount
FROM author
INNER JOIN book ON author.author_id=book.author_id
INNER JOIN genre ON book.genre_id=genre.genre_id
WHERE genre.genre_id IN(
    SELECT query_1.genre_id
    FROM (SELECT genre_id, MAX(amount) AS sum_amount
          FROM book 
          GROUP BY genre_id
          ORDER BY  sum_amount DESC
          ) AS query_1
    INNER JOIN (
    SELECT genre_id, MAX(amount) AS sum_amount
    FROM book 
    GROUP BY genre_id
    ORDER BY  sum_amount DESC
    LIMIT 2) AS query_2
    ON query_1.sum_amount=query_2.sum_amount)
ORDER BY title;
                        OR
SELECT title, name_author, name_genre, price, amount
FROM author
INNER JOIN book 
ON author.author_id = book.author_id
INNER JOIN genre 
ON book.genre_id = genre.genre_id
WHERE book.genre_id IN 
    (SELECT genre_id
     FROM book
     GROUP BY genre_id
     HAVING SUM(amount) >= ALL(SELECT SUM(amount) FROM book GROUP BY genre_id)
     )
ORDER BY title;

--Books that are already in stock (in the book table), but at a different price than in the supply, 
--it is necessary to increase the quantity in the book table by the value specified in the supply, and recalculate the price. And in the supply table, reset the quantity of these books.
UPDATE book b
INNER JOIN author a USING(author_id)
INNER JOIN genre g ON a.name_author=s.author AND b.title=s.title AND b.price<>s.price
SET b.price=IF(b.price=s.price, b.price, (b.price*b.amount+s.price*s.amount)/(b.amount+s.amount)),
    b.amount=b.amount+s.amount, s.amount=0;

--For the book "Стихотворения и поэмы" by Lermontov, choose the genre "Poetry", and for the book "Остров сокровищ" by Stevenson - "Adventures".
UPDATE book b
INNER JOIN author a USING (author_id)
SET b.genre_id=(
	SELECT genre_id
	FROM genre
	WHERE name_genre=CASE
	      WHEN b.title='Стихотворения и поэмы' AND a.name_author LIKE 'Lermontov%' THEN 'Poetry'
	      WHEN b.title='Остров сокровищ' AND a.name_author LIKE 'Stevenson%' THEN 'Adventures'
	      END)
WHERE a.name_author LIKE 'Lermontov%' OR a.name_author LIKE 'Stevenson%';

--Delete all authors and all their books, the total number of books of which is less than 20.
DELETE FROM book
WHERE author_id in (SELECT author_id
	            FROM book
	            GROUP BY author_id
	            HAVING SUM(amount)<20);

--Delete all authors who write in the genre "Poetry". Delete all books by these authors from the book table.
DELETE FROM author a
INNER JOIN book b USING(author_id)
INNER JOIN genre g USING(genre_id)
WHERE name_genre LIKE 'Poetry';

--How many times each book was ordered, the author of the book is displayed.
SELECT name_author, title, COUNT(bb.amount) AS amount
FROM author a
INNER JOIN book b USING(author_id)
LEFT JOIN buy_book bb USING(book_id)
GROUP BY name_author, title
ORDER  BY name_author, title;

--Numbers of all paid orders and the dates when they were paid.
SELECT buy_id, date_step_end 
FROM step s JOIN buy_step bb USING(step_id)
WHERE date_step_end is not Null 
	AND bb.step_id=1;

--Order numbers (buy_id) and names of the stages they are currently at. If the order has been delivered, no information about it is displayed.
SELECT DISTINCT buy_id, name_step
FROM buy_step bs INNER JOIN s ON bs.step_id=s.step_id
WHERE date_step_end is Null AND date_step_beg is not Null
ORDER BY buy_id ASC;

--In the city table, for each city, the number of days in which the order can be delivered to this city is indicated (only the "Transportation" stage is considered). For those orders that have passed the transportation stage, the number of days in which the order is actually delivered to the city is displayed. 
--Also, if the order is delivered late, the number of days of delay is indicated, otherwise 0 is displayed.
SELECT bs.buy_id, DATEDIFF(date_step_end, date_step_beg) AS 'days',
	IF(DATEDIFF(date_step_end, date_step_beg)>date_delivery, DATEDIFF(date_step_end, date_step_beg)-date_delivery, 0) AS 'lateness'
FROM city c
INNER JOIN client cl USING(city_id)
INNER JOIN buy b USING(client_id)
INNER JOIN buy_step bs USING(buy_id)
INNER JOIN step s USING(step_id)
WHERE name_step in('Transportation') AND date_step_end is not Null
ORDER BY buy_id;

--The genre in which the most copies of books were ordered, indicate this quantity
SELECT name_genre, SUM(bb.amount) AS 'amount'
FROM genre g INNER JOIN book b USING(genre_id)
             INNER JOIN buy_book bb USING(book_id)
GROUP BY name_genre
HAVING SUM(bb.amount)=(SELECT MAX(sum_amount) FROM (SELECT SUM(buy_book.amount) as sum_amount
	                                            FROM buy_book
	                                            INNER JOIN book USING(book_id)
                                                    INNER JOIN genre USING(genre_id)
	                                            GROUP BY genre_id) as query);

--Comparison of monthly book sales revenue for the current and previous years.
SELECT YEAR(date_payment) AS 'YEAR', MONTHNAME(date_payment) AS 'MONTH', SUM(amount*price) AS 'SUM' 
FROM buy_arhive
GROUP BY 1, 2
UNION
SELECT YEAR(date_payment) AS 'YEAR', MONTHNAME(date_payment) AS 'MONTH', SUM(bb.amount*b.price) AS 'SUM'
FROM buy_step INNER JOIN step s USING(step_id)
              INNER JOIN buy_book bb USING(buy_id)
              INNER JOIN book USING(book_id)
WHERE name_step in ('payment') AND date_step_end is not Null
GROUP BY 1, 2
ORDER BY 3 ASC;
   
--For each book, information is displayed on the number of copies sold and their cost for 2020 and 2019. For 2020, copies that have already been paid for were considered sold.
SELECT title, SUM(amount) AS 'Amount', SUM(sum) AS 'Sum'
FROM (SELECT b.title, SUM(ba.amount) AS 'amount', SUM(ba.price*ba.amount) AS 'sum'
	FROM buy_arhive ba INNER JOIN book USING(book_id)
      GROUP BY title
UNION ALL
      SELECT b.title, SUM(bb.amount) AS 'amount', SUM(b.price*bb.amount) AS 'sum'
      FROM step p
        INNER JOIN buy_step bs USING(step_id)
        INNER JOIN buy_book bb USING(buy_id)
        INNER JOIN book     b  USING(book_id)
      WHERE name_step in ('payment') AND bs.date_step_end is not Null
      GROUP BY b.title) AS query_1
GROUP BY title
ORDER BY Sum DESC;

--Deleting from the database information about orders for which payment was not completed within 24 hours from the date of placing the order.
DELETE FROM buy 
   INNER JOIN buy_step USING(buy_id)
   INNER JOIN step USING(step_id)
WHERE (DATEDIFF(date_step_end, date_step_beg)>1 OR date_step_end is Null) 
      AND step_id in(SELECT step_id FROM step WHERE name_step='payment');








