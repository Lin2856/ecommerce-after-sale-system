UPDATE primary_account
SET account_no = '13338907681',
    phone = '13338907681',
    updated_at = NOW()
WHERE account_no = 'merchant_admin_demo'
  AND account_type = 'MERCHANT'
  AND deleted = 0;

UPDATE primary_account
SET account_no = '13338907682',
    phone = '13338907682',
    updated_at = NOW()
WHERE account_no = '66666666'
  AND account_type = 'MERCHANT'
  AND deleted = 0;

UPDATE primary_account_ban
SET account_no = '13338907681',
    updated_at = NOW()
WHERE account_no = 'merchant_admin_demo'
  AND account_type = 'MERCHANT'
  AND deleted = 0;

UPDATE primary_account_ban
SET account_no = '13338907682',
    updated_at = NOW()
WHERE account_no = '66666666'
  AND account_type = 'MERCHANT'
  AND deleted = 0;

UPDATE twenty_mall_account
SET display_name = CASE account_no
  WHEN '20230140' THEN '松间寄星'
  WHEN '20230141' THEN '夏夜风铃'
  WHEN '22222222' THEN '云边小橘'
  WHEN '33333333' THEN '薄荷汽水铺'
  ELSE ELT(
    MOD(CAST(RIGHT(account_no, 2) AS UNSIGNED), 30) + 1,
    '雨后青柠', '晚风小邮差', '山茶拾光', '橘子海岸', '星河漫游者',
    '半糖栗子', '月亮便利贴', '晴天收藏家', '雾岛来信', '奶油小云',
    '南巷花火', '蓝莓汽泡', '春日野餐', '木星来客', '一颗小桃',
    '海盐日记', '落日飞行', '芋泥星球', '风里有糖', '清晨白鸽',
    '小熊软糖', '银河售票员', '桂花拿铁', '柠檬树下', '北窗听雨',
    '松果邮局', '白昼烟火', '慢热橙子', '云朵收纳盒', '薄雾森林'
  )
END,
updated_at = NOW()
WHERE account_role = 'CONSUMER'
  AND deleted = 0
  AND (
    display_name REGEXP '^万象商城(用户|消费者|批量买家|演示买家|学生买家)'
    OR display_name = account_no
  );
