USE ecommerce_after_sale;

CREATE TABLE IF NOT EXISTS admin_account (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  admin_code VARCHAR(32) NOT NULL UNIQUE COMMENT '管理员编码',
  admin_name VARCHAR(64) NOT NULL COMMENT '管理员名称',
  secret_key VARCHAR(32) NOT NULL COMMENT '管理员登录秘钥',
  avatar_key VARCHAR(64) DEFAULT NULL COMMENT '管理员头像标识',
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '账号状态：ACTIVE/DISABLED',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted TINYINT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员账号与秘钥表';

INSERT INTO admin_account (
  admin_code, admin_name, secret_key, avatar_key, status, deleted
) VALUES
  ('admin-a', '管理员 A', 'A7mP4qR2', 'admin-a', 'ACTIVE', 0),
  ('admin-b', '管理员 B', 'z9KxT3vB', 'admin-b', 'ACTIVE', 0),
  ('admin-c', '管理员 C', 'Q6nL8sWa', 'admin-c', 'ACTIVE', 0),
  ('admin-d', '管理员 D', 'b2Hc7YdM', 'admin-d', 'ACTIVE', 0)
ON DUPLICATE KEY UPDATE
  admin_name = VALUES(admin_name),
  secret_key = VALUES(secret_key),
  avatar_key = VALUES(avatar_key),
  status = VALUES(status),
  deleted = 0,
  updated_at = NOW();
