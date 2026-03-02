-- Incremental migration: old fai_db schema -> optimized schema (preserve data)
-- Target: MySQL 8.0+
-- Baseline: legacy structure exported in fai_db.sql (2026-03-01 old dump)
-- Run on the target database after taking backup.

USE `fai_db`;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 0) Helpers for idempotent DDL
-- =====================================================

DROP PROCEDURE IF EXISTS `sp_drop_index_if_exists`;
DROP PROCEDURE IF EXISTS `sp_drop_fk_if_exists`;
DROP PROCEDURE IF EXISTS `sp_add_index_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_unique_index_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_fk_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_check_if_missing`;

DELIMITER $$

CREATE PROCEDURE `sp_drop_index_if_exists`(
  IN p_table VARCHAR(64),
  IN p_index VARCHAR(64)
)
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND index_name = p_index
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` DROP INDEX `', p_index, '`');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

CREATE PROCEDURE `sp_drop_fk_if_exists`(
  IN p_table VARCHAR(64),
  IN p_fk VARCHAR(64)
)
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND constraint_name = p_fk
      AND constraint_type = 'FOREIGN KEY'
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` DROP FOREIGN KEY `', p_fk, '`');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

CREATE PROCEDURE `sp_add_index_if_missing`(
  IN p_table VARCHAR(64),
  IN p_index VARCHAR(64),
  IN p_cols_sql VARCHAR(255)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND index_name = p_index
  ) THEN
    SET @sql = CONCAT('CREATE INDEX `', p_index, '` ON `', p_table, '` ', p_cols_sql);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

CREATE PROCEDURE `sp_add_unique_index_if_missing`(
  IN p_table VARCHAR(64),
  IN p_index VARCHAR(64),
  IN p_cols_sql VARCHAR(255)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND index_name = p_index
  ) THEN
    SET @sql = CONCAT('CREATE UNIQUE INDEX `', p_index, '` ON `', p_table, '` ', p_cols_sql);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

CREATE PROCEDURE `sp_add_fk_if_missing`(
  IN p_table VARCHAR(64),
  IN p_fk VARCHAR(64),
  IN p_fk_sql TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND constraint_name = p_fk
      AND constraint_type = 'FOREIGN KEY'
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD CONSTRAINT `', p_fk, '` ', p_fk_sql);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

CREATE PROCEDURE `sp_add_check_if_missing`(
  IN p_table VARCHAR(64),
  IN p_check VARCHAR(64),
  IN p_check_sql TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = p_table
      AND constraint_name = p_check
      AND constraint_type = 'CHECK'
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD CONSTRAINT `', p_check, '` CHECK ', p_check_sql);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$

DELIMITER ;

-- =====================================================
-- 1) Data cleanup (to avoid constraint/unique failures)
-- =====================================================

-- normalize boolean fields
UPDATE `users`  SET `is_active` = 1 WHERE `is_active` IS NULL OR `is_active` NOT IN (0, 1);
UPDATE `alerts` SET `is_read`   = 0 WHERE `is_read`   IS NULL OR `is_read`   NOT IN (0, 1);

-- normalize financial amount (if negative, keep absolute to satisfy non-negative check)
UPDATE `financial_records` SET `amount` = ABS(`amount`) WHERE `amount` < 0;

-- normalize report period (safe swap)
UPDATE `reports` r
JOIN (
  SELECT `id`, `period_start` AS `old_start`, `period_end` AS `old_end`
  FROM `reports`
  WHERE `period_end` < `period_start`
) s ON s.`id` = r.`id`
SET r.`period_start` = s.`old_end`,
    r.`period_end` = s.`old_start`;

-- normalize budgets numeric ranges
UPDATE `budgets` SET `month` = LEAST(GREATEST(`month`, 1), 12) WHERE `month` < 1 OR `month` > 12;
UPDATE `budgets`
SET `year` = CASE
  WHEN `year` < 2000 THEN 2000
  WHEN `year` > 2100 THEN 2100
  ELSE `year`
END
WHERE `year` < 2000 OR `year` > 2100;

UPDATE `budgets` SET `planned_amount`  = 0 WHERE `planned_amount`  < 0;
UPDATE `budgets` SET `actual_amount`   = 0 WHERE `actual_amount`   < 0;
UPDATE `budgets` SET `forecast_amount` = 0 WHERE `forecast_amount` < 0;

-- Deduplicate budgets by business key before adding unique index.
-- Keep the newest row (largest id), remove older duplicates.
DELETE b1
FROM `budgets` b1
JOIN `budgets` b2
  ON b1.`company_id` = b2.`company_id`
 AND b1.`year` = b2.`year`
 AND b1.`month` = b2.`month`
 AND b1.`category` = b2.`category`
 AND b1.`id` < b2.`id`;

-- =====================================================
-- 2) Column defaults and nullability tightening
-- =====================================================

ALTER TABLE `companies`
  MODIFY `name` VARCHAR(100) NOT NULL,
  MODIFY `industry` VARCHAR(50) NULL,
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

SET @col_exists := (
  SELECT COUNT(1)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'users'
    AND column_name = 'company_super_admin'
);
SET @sql_add_col := IF(
  @col_exists = 0,
  'ALTER TABLE `users` ADD COLUMN `company_super_admin` TINYINT(1) NOT NULL DEFAULT 0 AFTER `company_id`',
  'SELECT 1'
);
PREPARE stmt_add_col FROM @sql_add_col;
EXECUTE stmt_add_col;
DEALLOCATE PREPARE stmt_add_col;

UPDATE `users` SET `company_super_admin` = 0
WHERE `company_super_admin` IS NULL OR `company_super_admin` NOT IN (0, 1);

-- backfill one super admin for each existing company: pick the earliest user (min id)
UPDATE `users` u
JOIN (
  SELECT `company_id`, MIN(`id`) AS `owner_id`
  FROM `users`
  WHERE `company_id` IS NOT NULL
  GROUP BY `company_id`
) x ON x.`owner_id` = u.`id`
SET u.`company_super_admin` = 1;

ALTER TABLE `users`
  MODIFY `username` VARCHAR(50) NOT NULL,
  MODIFY `email` VARCHAR(100) NOT NULL,
  MODIFY `hashed_password` VARCHAR(255) NOT NULL,
  MODIFY `role` ENUM('admin','accountant','viewer') NOT NULL DEFAULT 'viewer',
  MODIFY `company_super_admin` TINYINT(1) NOT NULL DEFAULT 0,
  MODIFY `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `financial_records`
  MODIFY `record_date` DATE NOT NULL,
  MODIFY `category` VARCHAR(50) NOT NULL,
  MODIFY `sub_category` VARCHAR(50) NULL,
  MODIFY `amount` DECIMAL(15,2) NOT NULL,
  MODIFY `description` VARCHAR(255) NULL,
  MODIFY `source` VARCHAR(50) NULL DEFAULT 'manual',
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `reports`
  MODIFY `report_type` ENUM('profit_loss','balance_sheet','cash_flow') NOT NULL,
  MODIFY `title` VARCHAR(200) NULL,
  MODIFY `period_start` DATE NOT NULL,
  MODIFY `period_end` DATE NOT NULL,
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `alerts`
  MODIFY `alert_type` VARCHAR(50) NOT NULL,
  MODIFY `severity` ENUM('low','medium','high') NOT NULL DEFAULT 'low',
  MODIFY `message` TEXT NOT NULL,
  MODIFY `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `budgets`
  MODIFY `year` INT NOT NULL,
  MODIFY `month` TINYINT UNSIGNED NOT NULL,
  MODIFY `category` VARCHAR(50) NOT NULL,
  MODIFY `planned_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  MODIFY `actual_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  MODIFY `forecast_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  MODIFY `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- =====================================================
-- 3) Foreign keys (adjust ON DELETE/ON UPDATE policy)
-- =====================================================

-- users.company_id: RESTRICT -> SET NULL
CALL `sp_drop_fk_if_exists`('users', 'users_ibfk_1');
CALL `sp_drop_fk_if_exists`('users', 'fk_users_company');
CALL `sp_add_fk_if_missing`(
  'users',
  'fk_users_company',
  'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL ON UPDATE CASCADE'
);

-- financial_records.created_by: RESTRICT -> SET NULL
CALL `sp_drop_fk_if_exists`('financial_records', 'financial_records_ibfk_2');
CALL `sp_drop_fk_if_exists`('financial_records', 'fk_fin_records_created_by');
CALL `sp_add_fk_if_missing`(
  'financial_records',
  'fk_fin_records_created_by',
  'FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE'
);

-- Rebuild company-side FKs with ON UPDATE CASCADE
CALL `sp_drop_fk_if_exists`('alerts', 'alerts_ibfk_1');
CALL `sp_drop_fk_if_exists`('alerts', 'fk_alerts_company');
CALL `sp_add_fk_if_missing`(
  'alerts',
  'fk_alerts_company',
  'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE'
);

CALL `sp_drop_fk_if_exists`('budgets', 'budgets_ibfk_1');
CALL `sp_drop_fk_if_exists`('budgets', 'fk_budgets_company');
CALL `sp_add_fk_if_missing`(
  'budgets',
  'fk_budgets_company',
  'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE'
);

CALL `sp_drop_fk_if_exists`('financial_records', 'financial_records_ibfk_1');
CALL `sp_drop_fk_if_exists`('financial_records', 'fk_fin_records_company');
CALL `sp_add_fk_if_missing`(
  'financial_records',
  'fk_fin_records_company',
  'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE'
);

CALL `sp_drop_fk_if_exists`('reports', 'reports_ibfk_1');
CALL `sp_drop_fk_if_exists`('reports', 'fk_reports_company');
CALL `sp_add_fk_if_missing`(
  'reports',
  'fk_reports_company',
  'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE'
);

-- =====================================================
-- 4) Index optimization
-- =====================================================

-- remove legacy single-column indexes that are covered by composite indexes
CALL `sp_drop_index_if_exists`('alerts', 'company_id');
CALL `sp_drop_index_if_exists`('budgets', 'company_id');
CALL `sp_drop_index_if_exists`('financial_records', 'company_id');
CALL `sp_drop_index_if_exists`('reports', 'company_id');
CALL `sp_drop_index_if_exists`('users', 'company_id');

-- add optimized indexes
CALL `sp_add_index_if_missing`('companies', 'idx_companies_created_at', '(`created_at`)');
CALL `sp_add_index_if_missing`('companies', 'idx_companies_name', '(`name`)');

CALL `sp_add_index_if_missing`('users', 'idx_users_company_role', '(`company_id`, `role`)');
CALL `sp_add_index_if_missing`('users', 'idx_users_company_super_admin', '(`company_id`, `company_super_admin`)');

CALL `sp_add_index_if_missing`('financial_records', 'idx_fin_records_company_date', '(`company_id`, `record_date`)');
CALL `sp_add_index_if_missing`('financial_records', 'idx_fin_records_company_category_date', '(`company_id`, `category`, `record_date`)');
CALL `sp_add_index_if_missing`('financial_records', 'idx_fin_records_created_by_created_at', '(`created_by`, `created_at`)');

CALL `sp_add_index_if_missing`('reports', 'idx_reports_company_created_at', '(`company_id`, `created_at`)');
CALL `sp_add_index_if_missing`('reports', 'idx_reports_company_type_period', '(`company_id`, `report_type`, `period_start`, `period_end`)');

CALL `sp_add_index_if_missing`('alerts', 'idx_alerts_company_read_created', '(`company_id`, `is_read`, `created_at`)');
CALL `sp_add_index_if_missing`('alerts', 'idx_alerts_company_severity_created', '(`company_id`, `severity`, `created_at`)');

CALL `sp_add_index_if_missing`('budgets', 'idx_budgets_company_year_month', '(`company_id`, `year`, `month`)');
CALL `sp_add_unique_index_if_missing`('budgets', 'uq_budgets_company_year_month_category', '(`company_id`, `year`, `month`, `category`)');

-- =====================================================
-- 5) Check constraints
-- =====================================================

CALL `sp_add_check_if_missing`('users', 'chk_users_is_active', '(`is_active` IN (0, 1))');
CALL `sp_add_check_if_missing`('users', 'chk_users_company_super_admin', '(`company_super_admin` IN (0, 1))');

CALL `sp_add_check_if_missing`('financial_records', 'chk_fin_records_amount_non_negative', '(`amount` >= 0)');

CALL `sp_add_check_if_missing`('reports', 'chk_reports_period_valid', '(`period_end` >= `period_start`)');

CALL `sp_add_check_if_missing`('alerts', 'chk_alerts_is_read', '(`is_read` IN (0, 1))');

CALL `sp_add_check_if_missing`('budgets', 'chk_budgets_month', '(`month` BETWEEN 1 AND 12)');
CALL `sp_add_check_if_missing`('budgets', 'chk_budgets_year', '(`year` BETWEEN 2000 AND 2100)');
CALL `sp_add_check_if_missing`('budgets', 'chk_budgets_planned_non_negative', '(`planned_amount` >= 0)');
CALL `sp_add_check_if_missing`('budgets', 'chk_budgets_actual_non_negative', '(`actual_amount` >= 0)');
CALL `sp_add_check_if_missing`('budgets', 'chk_budgets_forecast_non_negative', '(`forecast_amount` >= 0)');

DROP PROCEDURE IF EXISTS `sp_drop_index_if_exists`;
DROP PROCEDURE IF EXISTS `sp_drop_fk_if_exists`;
DROP PROCEDURE IF EXISTS `sp_add_index_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_unique_index_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_fk_if_missing`;
DROP PROCEDURE IF EXISTS `sp_add_check_if_missing`;

SET FOREIGN_KEY_CHECKS = 1;
