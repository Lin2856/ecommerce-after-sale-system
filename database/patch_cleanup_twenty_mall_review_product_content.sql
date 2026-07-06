USE ecommerce_after_sale;
SET NAMES utf8mb4;

UPDATE twenty_mall_review
SET content = TRIM(
  REPLACE(
    REPLACE(
      CASE
        WHEN LOCATE(CONCAT(CHAR(10), '商家服务评价：'), content) > 0
             AND LOCATE(CONCAT(CHAR(10), '补充：'), content) > LOCATE(CONCAT(CHAR(10), '商家服务评价：'), content)
          THEN CONCAT(
            SUBSTRING_INDEX(content, CONCAT(CHAR(10), '商家服务评价：'), 1),
            CHAR(10),
            '补充：',
            SUBSTRING_INDEX(content, CONCAT(CHAR(10), '补充：'), -1)
          )
        WHEN LOCATE(CONCAT(CHAR(10), '商家服务评价：'), content) > 0
          THEN SUBSTRING_INDEX(content, CONCAT(CHAR(10), '商家服务评价：'), 1)
        WHEN LOCATE('商家服务评价：', content) > 0
          THEN SUBSTRING_INDEX(content, '商家服务评价：', 1)
        ELSE content
      END,
      '商品评价：',
      ''
    ),
    '产品质量评价：',
    ''
  )
)
WHERE deleted = 0
  AND (
    content LIKE '%商家服务评价：%'
    OR content LIKE '%商品评价：%'
    OR content LIKE '%产品质量评价：%'
  );

SELECT COUNT(*) AS remaining_mixed_review_count
FROM twenty_mall_review
WHERE deleted = 0
  AND content LIKE '%商家服务评价：%';

SELECT COUNT(*) AS remaining_labeled_review_count
FROM twenty_mall_review
WHERE deleted = 0
  AND (
    content LIKE '%商品评价：%'
    OR content LIKE '%产品质量评价：%'
  );
