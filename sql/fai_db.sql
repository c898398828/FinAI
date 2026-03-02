/*
 Navicat Premium Data Transfer

 Source Server         : MQ8
 Source Server Type    : MySQL
 Source Server Version : 80041 (8.0.41)
 Source Host           : localhost:3306
 Source Schema         : fai_db

 Target Server Type    : MySQL
 Target Server Version : 80041 (8.0.41)
 File Encoding         : 65001

 Date: 02/03/2026 19:53:10
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for alerts
-- ----------------------------
DROP TABLE IF EXISTS `alerts`;
CREATE TABLE `alerts`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `company_id` int NOT NULL,
  `alert_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `severity` enum('low','medium','high') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'low',
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `data_json` json NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_alerts_company_read_created`(`company_id` ASC, `is_read` ASC, `created_at` ASC) USING BTREE,
  INDEX `idx_alerts_company_severity_created`(`company_id` ASC, `severity` ASC, `created_at` ASC) USING BTREE,
  CONSTRAINT `fk_alerts_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_alerts_is_read` CHECK (`is_read` in (0,1))
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of alerts
-- ----------------------------
INSERT INTO `alerts` VALUES (1, 1, '收入异常', 'medium', '2026-02 收入 ¥577,636.72 明显偏高（均值 ¥278,712.75）', 1, '{\"mean\": 278712.75, \"month\": \"2026-02\", \"amount\": 577636.72, \"message\": \"2026-02 收入 ¥577,636.72 明显偏高（均值 ¥278,712.75）\", \"z_score\": 2.0, \"category\": \"收入\", \"severity\": \"medium\"}', '2026-03-01 12:23:35');
INSERT INTO `alerts` VALUES (2, 1, '支出异常', 'medium', '2026-03 支出 ¥337,248.01 明显偏高（均值 ¥179,765.32）', 1, '{\"mean\": 179765.32, \"month\": \"2026-03\", \"amount\": 337248.01, \"message\": \"2026-03 支出 ¥337,248.01 明显偏高（均值 ¥179,765.32）\", \"z_score\": 2.11, \"category\": \"支出\", \"severity\": \"medium\"}', '2026-03-01 12:23:35');
INSERT INTO `alerts` VALUES (3, 1, '资产异常', 'high', '2026-03 资产 ¥5,735,970.39 明显偏高（均值 ¥1,088,755.80）', 1, '{\"mean\": 1088755.8, \"month\": \"2026-03\", \"amount\": 5735970.39, \"message\": \"2026-03 资产 ¥5,735,970.39 明显偏高（均值 ¥1,088,755.80）\", \"z_score\": 3.3, \"category\": \"资产\", \"severity\": \"high\"}', '2026-03-01 12:23:35');
INSERT INTO `alerts` VALUES (4, 888888888, '资产异常', 'medium', '2026-03 资产 ¥5,999,999.00 明显偏高（均值 ¥1,038,925.83）', 0, '{\"mean\": 1038925.83, \"month\": \"2026-03\", \"amount\": 5999999.0, \"message\": \"2026-03 资产 ¥5,999,999.00 明显偏高（均值 ¥1,038,925.83）\", \"z_score\": 2.45, \"category\": \"资产\", \"severity\": \"medium\"}', '2026-03-02 06:41:29');
INSERT INTO `alerts` VALUES (5, 888888888, '负债异常', 'medium', '2026-03 负债 ¥0.00 明显偏低（均值 ¥308,469.23）', 0, '{\"mean\": 308469.23, \"month\": \"2026-03\", \"amount\": 0, \"message\": \"2026-03 负债 ¥0.00 明显偏低（均值 ¥308,469.23）\", \"z_score\": -2.29, \"category\": \"负债\", \"severity\": \"medium\"}', '2026-03-02 06:41:29');

-- ----------------------------
-- Table structure for budgets
-- ----------------------------
DROP TABLE IF EXISTS `budgets`;
CREATE TABLE `budgets`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `company_id` int NOT NULL,
  `year` int NOT NULL,
  `month` tinyint UNSIGNED NOT NULL,
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `planned_amount` decimal(15, 2) NOT NULL DEFAULT 0.00,
  `actual_amount` decimal(15, 2) NOT NULL DEFAULT 0.00,
  `forecast_amount` decimal(15, 2) NOT NULL DEFAULT 0.00,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uq_budgets_company_year_month_category`(`company_id` ASC, `year` ASC, `month` ASC, `category` ASC) USING BTREE,
  INDEX `idx_budgets_company_year_month`(`company_id` ASC, `year` ASC, `month` ASC) USING BTREE,
  CONSTRAINT `fk_budgets_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_budgets_actual_non_negative` CHECK (`actual_amount` >= 0),
  CONSTRAINT `chk_budgets_forecast_non_negative` CHECK (`forecast_amount` >= 0),
  CONSTRAINT `chk_budgets_month` CHECK (`month` between 1 and 12),
  CONSTRAINT `chk_budgets_planned_non_negative` CHECK (`planned_amount` >= 0),
  CONSTRAINT `chk_budgets_year` CHECK (`year` between 2000 and 2100)
) ENGINE = InnoDB AUTO_INCREMENT = 66 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of budgets
-- ----------------------------
INSERT INTO `budgets` VALUES (1, 1, 2026, 3, '推广', 1999.00, 0.00, 0.00, '2026-03-01 07:07:29');
INSERT INTO `budgets` VALUES (2, 1, 2026, 1, '办公', 1048.95, 0.00, 1048.95, '2026-03-01 07:11:33');
INSERT INTO `budgets` VALUES (3, 1, 2026, 1, '销售收入', 19948.95, 0.00, 19948.95, '2026-03-01 07:11:33');
INSERT INTO `budgets` VALUES (4, 1, 2026, 1, '资产变现', 5250000.00, 0.00, 5250000.00, '2026-03-01 07:15:48');
INSERT INTO `budgets` VALUES (5, 1, 2026, 1, '购买物料', 105000.00, 0.00, 105000.00, '2026-03-01 07:15:48');
INSERT INTO `budgets` VALUES (6, 1, 2026, 1, '工资', 52500.00, 0.00, 52500.00, '2026-03-01 07:15:48');
INSERT INTO `budgets` VALUES (7, 1, 2026, 4, '收入', 0.00, 0.00, 279318.07, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (8, 1, 2026, 5, '收入', 0.00, 0.00, 279318.07, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (9, 1, 2026, 6, '收入', 0.00, 0.00, 279318.07, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (10, 1, 2026, 4, '支出', 0.00, 0.00, 389033.66, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (11, 1, 2026, 5, '支出', 0.00, 0.00, 389033.66, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (12, 1, 2026, 6, '支出', 0.00, 0.00, 389033.66, '2026-03-01 12:20:46');
INSERT INTO `budgets` VALUES (13, 1, 2026, 1, '水电网络', 4830.33, 0.00, 4830.33, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (14, 1, 2026, 1, '办公租金', 21709.73, 0.00, 21709.73, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (15, 1, 2026, 1, '投资收益', 15357.50, 0.00, 15357.50, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (16, 1, 2026, 1, '人员工资', 106940.59, 0.00, 106940.59, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (17, 1, 2026, 1, '咨询收入', 56715.57, 0.00, 56715.57, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (18, 1, 2026, 1, '银行存款', 410025.15, 0.00, 410025.15, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (19, 1, 2026, 1, '服务收入', 63724.75, 0.00, 63724.75, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (20, 1, 2026, 1, '办公用品', 6415.05, 0.00, 6415.05, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (21, 1, 2026, 1, '应收账款', 112969.78, 0.00, 112969.78, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (22, 1, 2026, 1, '差旅费用', 10868.53, 0.00, 10868.53, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (23, 1, 2026, 1, '市场推广', 33445.46, 0.00, 33445.46, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (24, 1, 2026, 1, '应付工资', 98354.35, 0.00, 98354.35, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (25, 1, 2026, 1, '固定资产', 190909.15, 0.00, 190909.15, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (26, 1, 2026, 1, '产品销售', 162233.98, 0.00, 162233.98, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (27, 1, 2026, 1, '应付账款', 139543.65, 0.00, 139543.65, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (28, 1, 2026, 1, '短期借款', 219969.76, 0.00, 219969.76, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (29, 1, 2026, 1, '软件服务', 12596.26, 0.00, 12596.26, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (30, 1, 2026, 1, '银行贷款', 120138.91, 0.00, 120138.91, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (31, 1, 2026, 1, '利息收入', 40111.61, 0.00, 40111.61, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (32, 1, 2026, 1, '设备购置', 90864.28, 0.00, 90864.28, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (33, 1, 2026, 1, '员工工资', 17073.38, 0.00, 17073.38, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (34, 1, 2026, 1, '差旅费', 31216.18, 0.00, 31216.18, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (35, 1, 2026, 1, '项目回款', 43909.67, 0.00, 43909.67, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (36, 1, 2026, 1, '库存增加', 61138.84, 0.00, 61138.84, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (37, 1, 2026, 1, '水电费', 20929.73, 0.00, 20929.73, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (38, 1, 2026, 1, '银行存款增加', 144022.58, 0.00, 144022.58, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (39, 1, 2026, 1, '房租', 17477.74, 0.00, 17477.74, '2026-03-01 12:20:51');
INSERT INTO `budgets` VALUES (40, 888888888, 2026, 1, '库存增加', 61138.84, 0.00, 61138.84, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (41, 888888888, 2026, 1, '设备购置', 90864.28, 0.00, 90864.28, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (42, 888888888, 2026, 1, '项目回款', 43909.67, 0.00, 43909.67, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (43, 888888888, 2026, 1, '银行存款增加', 144022.58, 0.00, 144022.58, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (44, 888888888, 2026, 1, '咨询收入', 76043.64, 0.00, 76043.64, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (45, 888888888, 2026, 1, '银行贷款', 120138.91, 0.00, 120138.91, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (46, 888888888, 2026, 1, '短期借款', 157910.08, 0.00, 157910.08, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (47, 888888888, 2026, 1, '水电费', 20929.73, 0.00, 20929.73, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (48, 888888888, 2026, 1, '差旅费', 31216.18, 0.00, 31216.18, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (49, 888888888, 2026, 1, '房租', 17477.74, 0.00, 17477.74, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (50, 888888888, 2026, 1, '服务收入', 21920.74, 0.00, 21920.74, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (51, 888888888, 2026, 1, '应付账款', 119848.97, 0.00, 119848.97, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (52, 888888888, 2026, 1, '利息收入', 40111.61, 0.00, 40111.61, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (53, 888888888, 2026, 1, '办公用品', 9465.33, 0.00, 9465.33, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (54, 888888888, 2026, 1, '市场推广', 27861.68, 0.00, 27861.68, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (55, 888888888, 2026, 1, '产品销售', 64148.03, 0.00, 64148.03, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (56, 888888888, 2026, 1, '员工工资', 17073.38, 0.00, 17073.38, '2026-03-02 05:37:07');
INSERT INTO `budgets` VALUES (57, 888888888, 2026, 3, '收入', 0.00, 0.00, 982746.85, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (58, 888888888, 2026, 4, '收入', 0.00, 0.00, 145000.00, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (59, 888888888, 2026, 5, '收入', 0.00, 0.00, 152000.00, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (60, 888888888, 2026, 3, '支出', 0.00, 0.00, 69103.66, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (61, 888888888, 2026, 4, '支出', 0.00, 0.00, 125000.00, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (62, 888888888, 2026, 5, '支出', 0.00, 0.00, 130000.00, '2026-03-02 06:03:52');
INSERT INTO `budgets` VALUES (63, 888888888, 2026, 6, '收入', 0.00, 0.00, 158000.00, '2026-03-02 07:06:46');
INSERT INTO `budgets` VALUES (64, 888888888, 2026, 6, '支出', 0.00, 0.00, 135000.00, '2026-03-02 07:06:46');
INSERT INTO `budgets` VALUES (65, 888888888, 2026, 1, '资产变现', 6299998.95, 0.00, 6299998.95, '2026-03-02 07:06:49');

-- ----------------------------
-- Table structure for companies
-- ----------------------------
DROP TABLE IF EXISTS `companies`;
CREATE TABLE `companies`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `industry` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_companies_created_at`(`created_at` ASC) USING BTREE,
  INDEX `idx_companies_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 888888889 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of companies
-- ----------------------------
INSERT INTO `companies` VALUES (1, '小崔国际', '零售业', '2026-03-01 06:26:37');
INSERT INTO `companies` VALUES (578598105, '测试', '零售业', '2026-03-01 15:24:50');
INSERT INTO `companies` VALUES (888888888, '小崔国际', '零售业', '2026-03-01 07:21:32');

-- ----------------------------
-- Table structure for financial_records
-- ----------------------------
DROP TABLE IF EXISTS `financial_records`;
CREATE TABLE `financial_records`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `company_id` int NOT NULL,
  `record_date` date NOT NULL,
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sub_category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `amount` decimal(15, 2) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `source` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'manual',
  `created_by` int NULL DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_fin_records_company_date`(`company_id` ASC, `record_date` ASC) USING BTREE,
  INDEX `idx_fin_records_company_category_date`(`company_id` ASC, `category` ASC, `record_date` ASC) USING BTREE,
  INDEX `idx_fin_records_created_by_created_at`(`created_by` ASC, `created_at` ASC) USING BTREE,
  CONSTRAINT `fk_fin_records_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_fin_records_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_fin_records_amount_non_negative` CHECK (`amount` >= 0)
) ENGINE = InnoDB AUTO_INCREMENT = 458 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of financial_records
-- ----------------------------
INSERT INTO `financial_records` VALUES (1, 1, '2026-03-08', '支出', '办公', 999.00, '办公支出', 'manual', 1, '2026-03-01 07:06:51');
INSERT INTO `financial_records` VALUES (2, 1, '2026-03-01', '收入', '销售收入', 18999.00, NULL, 'manual', 1, '2026-03-01 07:08:07');
INSERT INTO `financial_records` VALUES (3, 1, '2026-03-01', '资产', '资产变现', 5000000.00, NULL, 'manual', 1, '2026-03-01 07:13:29');
INSERT INTO `financial_records` VALUES (4, 1, '2026-03-01', '支出', '购买物料', 100000.00, NULL, 'manual', 1, '2026-03-01 07:14:11');
INSERT INTO `financial_records` VALUES (5, 1, '2026-03-01', '支出', '工资', 50000.00, '需发工资', 'manual', 1, '2026-03-01 07:15:32');
INSERT INTO `financial_records` VALUES (6, 1, '2025-05-12', '资产', '固定资产', 179847.45, '办公家具', 'mock', 1, '2025-05-15 16:28:00');
INSERT INTO `financial_records` VALUES (7, 1, '2025-06-17', '资产', '银行存款', 486438.65, '招商银行活期', 'mock', 1, '2025-06-03 10:04:00');
INSERT INTO `financial_records` VALUES (8, 1, '2025-10-26', '负债', '应付工资', 96749.24, '社保公积金', 'mock', 1, '2025-10-01 09:18:00');
INSERT INTO `financial_records` VALUES (9, 1, '2025-04-28', '支出', '水电网络', 3528.53, '水电费', 'mock', 1, '2025-04-08 09:24:00');
INSERT INTO `financial_records` VALUES (10, 1, '2025-09-24', '资产', '银行存款', 340446.26, '工商银行定期', 'mock', 1, '2025-09-06 15:58:00');
INSERT INTO `financial_records` VALUES (11, 1, '2026-02-10', '收入', '咨询收入', 29497.02, '管理咨询服务', 'mock', 1, '2026-02-22 16:10:00');
INSERT INTO `financial_records` VALUES (12, 1, '2025-07-05', '支出', '差旅费用', 3422.78, '展会参展费用', 'mock', 1, '2025-07-14 10:02:00');
INSERT INTO `financial_records` VALUES (13, 1, '2025-12-02', '支出', '软件服务', 12123.61, '软件许可证', 'mock', 1, '2025-12-15 09:20:00');
INSERT INTO `financial_records` VALUES (14, 1, '2025-04-19', '收入', '服务收入', 36815.44, '技术支持服务', 'mock', 1, '2025-04-14 08:01:00');
INSERT INTO `financial_records` VALUES (15, 1, '2025-08-11', '收入', '产品销售', 157891.37, '线下渠道销售', 'mock', 1, '2025-08-01 09:56:00');
INSERT INTO `financial_records` VALUES (16, 1, '2025-07-20', '收入', '服务收入', 55499.39, '定制开发收入', 'mock', 1, '2025-07-26 18:33:00');
INSERT INTO `financial_records` VALUES (17, 1, '2025-09-08', '负债', '应付工资', 99362.12, '社保公积金', 'mock', 1, '2025-09-21 09:49:00');
INSERT INTO `financial_records` VALUES (18, 1, '2025-07-12', '支出', '水电网络', 4339.67, '水电费', 'mock', 1, '2025-07-07 18:15:00');
INSERT INTO `financial_records` VALUES (19, 1, '2025-06-13', '资产', '应收账款', 115154.24, '客户 A 应收', 'mock', 1, '2025-06-04 17:15:00');
INSERT INTO `financial_records` VALUES (20, 1, '2025-06-03', '支出', '市场推广', 10465.95, '线上广告投放', 'mock', 1, '2025-06-25 11:10:00');
INSERT INTO `financial_records` VALUES (21, 1, '2026-03-08', '支出', '水电网络', 4714.04, '网络通信费', 'mock', 1, '2026-03-05 17:13:00');
INSERT INTO `financial_records` VALUES (22, 1, '2025-09-13', '支出', '差旅费用', 3619.85, '展会参展费用', 'mock', 1, '2025-09-16 08:22:00');
INSERT INTO `financial_records` VALUES (23, 1, '2026-01-26', '支出', '办公用品', 7828.70, '打印耗材', 'mock', 1, '2026-01-27 18:09:00');
INSERT INTO `financial_records` VALUES (24, 1, '2026-02-18', '负债', '短期借款', 67182.02, '信用借款', 'mock', 1, '2026-02-04 15:23:00');
INSERT INTO `financial_records` VALUES (25, 1, '2026-01-02', '负债', '短期借款', 77128.82, '银行流动资金贷款', 'mock', 1, '2026-01-11 08:18:00');
INSERT INTO `financial_records` VALUES (26, 1, '2025-09-24', '收入', '咨询收入', 38776.52, '财务咨询项目', 'mock', 1, '2025-09-28 15:28:00');
INSERT INTO `financial_records` VALUES (27, 1, '2026-02-20', '收入', '产品销售', 196254.01, 'A 产品线销售', 'mock', 1, '2026-02-28 14:39:00');
INSERT INTO `financial_records` VALUES (28, 1, '2025-04-15', '资产', '应收账款', 70189.38, '客户 A 应收', 'mock', 1, '2025-04-13 12:59:00');
INSERT INTO `financial_records` VALUES (29, 1, '2025-04-23', '支出', '人员工资', 117963.48, '销售团队薪资', 'mock', 1, '2025-04-14 13:17:00');
INSERT INTO `financial_records` VALUES (30, 1, '2025-04-04', '支出', '办公租金', 18068.61, '分部办公室租金', 'mock', 1, '2025-04-03 14:06:00');
INSERT INTO `financial_records` VALUES (31, 1, '2026-03-02', '支出', '办公租金', 21246.35, '分部办公室租金', 'mock', 1, '2026-03-23 13:13:00');
INSERT INTO `financial_records` VALUES (32, 1, '2025-09-14', '支出', '市场推广', 28954.05, '线上广告投放', 'mock', 1, '2025-09-14 13:34:00');
INSERT INTO `financial_records` VALUES (33, 1, '2025-12-06', '支出', '办公用品', 5378.20, '办公设备采购', 'mock', 1, '2025-12-19 14:40:00');
INSERT INTO `financial_records` VALUES (34, 1, '2025-08-18', '支出', '市场推广', 25905.31, '品牌推广费', 'mock', 1, '2025-08-05 11:26:00');
INSERT INTO `financial_records` VALUES (35, 1, '2025-10-18', '负债', '短期借款', 68757.11, '信用借款', 'mock', 1, '2025-10-25 11:44:00');
INSERT INTO `financial_records` VALUES (36, 1, '2025-07-08', '负债', '短期借款', 103870.66, '银行流动资金贷款', 'mock', 1, '2025-07-01 18:12:00');
INSERT INTO `financial_records` VALUES (37, 1, '2025-06-03', '负债', '应付工资', 97759.31, '本月应付薪资', 'mock', 1, '2025-06-18 11:32:00');
INSERT INTO `financial_records` VALUES (38, 1, '2026-03-15', '收入', '投资收益', 11917.95, '股权投资分红', 'mock', 1, '2026-03-12 18:47:00');
INSERT INTO `financial_records` VALUES (39, 1, '2025-10-23', '支出', '办公租金', 23541.88, '总部办公室租金', 'mock', 1, '2025-10-25 12:54:00');
INSERT INTO `financial_records` VALUES (40, 1, '2025-06-02', '收入', '咨询收入', 23459.91, '战略规划咨询', 'mock', 1, '2025-06-22 18:41:00');
INSERT INTO `financial_records` VALUES (41, 1, '2025-07-26', '资产', '固定资产', 240200.08, '办公设备', 'mock', 1, '2025-07-23 09:24:00');
INSERT INTO `financial_records` VALUES (42, 1, '2025-11-09', '支出', '差旅费用', 8197.28, '客户拜访差旅', 'mock', 1, '2025-11-28 15:07:00');
INSERT INTO `financial_records` VALUES (43, 1, '2025-09-13', '支出', '办公用品', 4550.74, '办公设备采购', 'mock', 1, '2025-09-25 17:44:00');
INSERT INTO `financial_records` VALUES (44, 1, '2026-02-15', '资产', '固定资产', 184473.73, '办公设备', 'mock', 1, '2026-02-03 10:48:00');
INSERT INTO `financial_records` VALUES (45, 1, '2025-07-28', '支出', '软件服务', 11599.71, '软件许可证', 'mock', 1, '2025-07-14 17:47:00');
INSERT INTO `financial_records` VALUES (46, 1, '2026-02-10', '收入', '投资收益', 8464.82, '基金收益', 'mock', 1, '2026-02-21 14:44:00');
INSERT INTO `financial_records` VALUES (47, 1, '2025-11-12', '收入', '服务收入', 63693.43, '定制开发收入', 'mock', 1, '2025-11-23 15:17:00');
INSERT INTO `financial_records` VALUES (48, 1, '2025-04-01', '收入', '咨询收入', 12125.89, '战略规划咨询', 'mock', 1, '2025-04-18 11:45:00');
INSERT INTO `financial_records` VALUES (49, 1, '2025-08-02', '收入', '服务收入', 79350.04, '定制开发收入', 'mock', 1, '2025-08-04 17:27:00');
INSERT INTO `financial_records` VALUES (50, 1, '2025-06-10', '支出', '差旅费用', 14353.64, '团队外出培训', 'mock', 1, '2025-06-14 16:42:00');
INSERT INTO `financial_records` VALUES (51, 1, '2025-12-12', '支出', '差旅费用', 14863.01, '团队外出培训', 'mock', 1, '2025-12-14 13:20:00');
INSERT INTO `financial_records` VALUES (52, 1, '2025-07-26', '资产', '银行存款', 273968.76, '招商银行活期', 'mock', 1, '2025-07-26 10:56:00');
INSERT INTO `financial_records` VALUES (53, 1, '2026-03-14', '支出', '人员工资', 111636.71, '销售团队薪资', 'mock', 1, '2026-03-21 09:53:00');
INSERT INTO `financial_records` VALUES (54, 1, '2025-06-15', '负债', '短期借款', 84540.99, '信用借款', 'mock', 1, '2025-06-11 09:00:00');
INSERT INTO `financial_records` VALUES (55, 1, '2025-08-10', '支出', '差旅费用', 8667.13, '团队外出培训', 'mock', 1, '2025-08-07 14:50:00');
INSERT INTO `financial_records` VALUES (56, 1, '2025-09-22', '收入', '产品销售', 198239.04, '线上渠道销售', 'mock', 1, '2025-09-17 16:38:00');
INSERT INTO `financial_records` VALUES (57, 1, '2025-07-26', '资产', '应收账款', 87428.19, '客户 B 应收', 'mock', 1, '2025-07-14 18:55:00');
INSERT INTO `financial_records` VALUES (58, 1, '2026-01-26', '收入', '投资收益', 25845.89, '股权投资分红', 'mock', 1, '2026-01-17 12:52:00');
INSERT INTO `financial_records` VALUES (59, 1, '2025-05-24', '支出', '办公租金', 16842.48, '总部办公室租金', 'mock', 1, '2025-05-24 12:32:00');
INSERT INTO `financial_records` VALUES (60, 1, '2025-04-18', '支出', '办公用品', 2981.13, '日常办公耗材', 'mock', 1, '2025-04-10 18:39:00');
INSERT INTO `financial_records` VALUES (61, 1, '2026-03-10', '收入', '咨询收入', 14972.68, '财务咨询项目', 'mock', 1, '2026-03-16 09:06:00');
INSERT INTO `financial_records` VALUES (62, 1, '2026-01-28', '支出', '人员工资', 67400.38, '管理层薪资', 'mock', 1, '2026-01-05 15:34:00');
INSERT INTO `financial_records` VALUES (63, 1, '2026-03-01', '资产', '银行存款', 497506.85, '建设银行账户', 'mock', 1, '2026-03-09 10:08:00');
INSERT INTO `financial_records` VALUES (64, 1, '2025-12-10', '负债', '短期借款', 142535.24, '银行流动资金贷款', 'mock', 1, '2025-12-18 08:35:00');
INSERT INTO `financial_records` VALUES (65, 1, '2025-11-25', '资产', '固定资产', 129208.71, '办公设备', 'mock', 1, '2025-11-07 18:13:00');
INSERT INTO `financial_records` VALUES (66, 1, '2026-02-27', '负债', '应付工资', 112135.60, '社保公积金', 'mock', 1, '2026-02-21 13:06:00');
INSERT INTO `financial_records` VALUES (67, 1, '2025-06-14', '支出', '人员工资', 73166.49, '销售团队薪资', 'mock', 1, '2025-06-06 12:29:00');
INSERT INTO `financial_records` VALUES (68, 1, '2026-02-22', '负债', '应付账款', 113064.04, '原材料应付', 'mock', 1, '2026-02-13 16:23:00');
INSERT INTO `financial_records` VALUES (69, 1, '2025-10-11', '资产', '应收账款', 103332.39, '客户 B 应收', 'mock', 1, '2025-10-01 15:54:00');
INSERT INTO `financial_records` VALUES (70, 1, '2025-07-27', '支出', '办公租金', 22444.13, '分部办公室租金', 'mock', 1, '2025-07-09 08:00:00');
INSERT INTO `financial_records` VALUES (71, 1, '2025-11-22', '收入', '产品销售', 126175.37, 'C 产品线销售', 'mock', 1, '2025-11-19 13:30:00');
INSERT INTO `financial_records` VALUES (72, 1, '2025-12-10', '收入', '投资收益', 11556.97, '基金收益', 'mock', 1, '2025-12-23 14:17:00');
INSERT INTO `financial_records` VALUES (73, 1, '2026-03-23', '收入', '服务收入', 78167.83, 'SaaS 订阅收入', 'mock', 1, '2026-03-10 18:26:00');
INSERT INTO `financial_records` VALUES (74, 1, '2026-02-25', '支出', '差旅费用', 11768.39, '展会参展费用', 'mock', 1, '2026-02-24 18:43:00');
INSERT INTO `financial_records` VALUES (75, 1, '2025-05-14', '收入', '咨询收入', 13900.78, '战略规划咨询', 'mock', 1, '2025-05-20 09:24:00');
INSERT INTO `financial_records` VALUES (76, 1, '2025-04-26', '支出', '市场推广', 17140.28, '品牌推广费', 'mock', 1, '2025-04-02 15:34:00');
INSERT INTO `financial_records` VALUES (77, 1, '2025-04-06', '支出', '软件服务', 7990.85, 'SaaS 工具订阅', 'mock', 1, '2025-04-12 13:13:00');
INSERT INTO `financial_records` VALUES (78, 1, '2025-06-02', '支出', '办公用品', 4492.69, '办公设备采购', 'mock', 1, '2025-06-06 14:00:00');
INSERT INTO `financial_records` VALUES (79, 1, '2025-12-14', '支出', '水电网络', 5712.49, '网络通信费', 'mock', 1, '2025-12-23 15:18:00');
INSERT INTO `financial_records` VALUES (80, 1, '2026-02-05', '支出', '软件服务', 10322.60, '软件许可证', 'mock', 1, '2026-02-03 12:20:00');
INSERT INTO `financial_records` VALUES (81, 1, '2026-03-13', '支出', '办公用品', 8295.80, '日常办公耗材', 'mock', 1, '2026-03-09 11:07:00');
INSERT INTO `financial_records` VALUES (82, 1, '2025-09-18', '支出', '水电网络', 3962.52, '网络通信费', 'mock', 1, '2025-09-24 16:51:00');
INSERT INTO `financial_records` VALUES (83, 1, '2026-01-23', '资产', '应收账款', 120868.44, '客户 C 应收', 'mock', 1, '2026-01-25 15:55:00');
INSERT INTO `financial_records` VALUES (84, 1, '2025-07-22', '收入', '咨询收入', 11536.81, '管理咨询服务', 'mock', 1, '2025-07-04 10:16:00');
INSERT INTO `financial_records` VALUES (85, 1, '2025-06-22', '负债', '应付账款', 73542.78, '供应商 A 应付', 'mock', 1, '2025-06-23 13:15:00');
INSERT INTO `financial_records` VALUES (86, 1, '2026-03-22', '资产', '应收账款', 119932.33, '客户 A 应收', 'mock', 1, '2026-03-28 08:08:00');
INSERT INTO `financial_records` VALUES (87, 1, '2025-07-25', '负债', '应付工资', 82117.19, '本月应付薪资', 'mock', 1, '2025-07-09 13:41:00');
INSERT INTO `financial_records` VALUES (88, 1, '2025-04-21', '资产', '银行存款', 417240.66, '建设银行账户', 'mock', 1, '2025-04-03 17:40:00');
INSERT INTO `financial_records` VALUES (89, 1, '2025-09-11', '负债', '应付账款', 48408.09, '供应商 B 应付', 'mock', 1, '2025-09-11 14:17:00');
INSERT INTO `financial_records` VALUES (90, 1, '2025-08-14', '资产', '固定资产', 241683.46, '服务器设备', 'mock', 1, '2025-08-21 17:12:00');
INSERT INTO `financial_records` VALUES (91, 1, '2025-11-06', '负债', '应付账款', 46950.43, '供应商 A 应付', 'mock', 1, '2025-11-18 09:10:00');
INSERT INTO `financial_records` VALUES (92, 1, '2025-04-23', '支出', '差旅费用', 13248.36, '客户拜访差旅', 'mock', 1, '2025-04-03 08:42:00');
INSERT INTO `financial_records` VALUES (93, 1, '2025-07-08', '收入', '产品销售', 128804.64, 'A 产品线销售', 'mock', 1, '2025-07-12 12:10:00');
INSERT INTO `financial_records` VALUES (94, 1, '2026-01-19', '支出', '差旅费用', 8700.11, '展会参展费用', 'mock', 1, '2026-01-11 09:55:00');
INSERT INTO `financial_records` VALUES (95, 1, '2025-08-12', '支出', '人员工资', 120148.55, '销售团队薪资', 'mock', 1, '2025-08-14 09:42:00');
INSERT INTO `financial_records` VALUES (96, 1, '2026-03-22', '支出', '差旅费用', 16669.28, '客户拜访差旅', 'mock', 1, '2026-03-07 18:40:00');
INSERT INTO `financial_records` VALUES (97, 1, '2025-10-21', '支出', '水电网络', 3390.20, '物业管理费', 'mock', 1, '2025-10-09 17:51:00');
INSERT INTO `financial_records` VALUES (98, 1, '2025-04-08', '收入', '产品销售', 141842.09, 'C 产品线销售', 'mock', 1, '2025-04-08 10:47:00');
INSERT INTO `financial_records` VALUES (99, 1, '2025-11-23', '支出', '办公租金', 17072.68, '总部办公室租金', 'mock', 1, '2025-11-18 10:17:00');
INSERT INTO `financial_records` VALUES (100, 1, '2025-06-07', '支出', '水电网络', 4876.09, '网络通信费', 'mock', 1, '2025-06-02 17:47:00');
INSERT INTO `financial_records` VALUES (101, 1, '2025-11-14', '资产', '应收账款', 99224.46, '客户 C 应收', 'mock', 1, '2025-11-10 17:39:00');
INSERT INTO `financial_records` VALUES (102, 1, '2025-09-23', '支出', '人员工资', 96933.02, '研发团队薪资', 'mock', 1, '2025-09-10 11:17:00');
INSERT INTO `financial_records` VALUES (103, 1, '2025-09-27', '负债', '短期借款', 180553.39, '信用借款', 'mock', 1, '2025-09-03 15:01:00');
INSERT INTO `financial_records` VALUES (104, 1, '2025-12-07', '资产', '应收账款', 144592.69, '客户 A 应收', 'mock', 1, '2025-12-17 13:39:00');
INSERT INTO `financial_records` VALUES (105, 1, '2025-12-28', '资产', '银行存款', 270830.63, '工商银行定期', 'mock', 1, '2025-12-17 08:42:00');
INSERT INTO `financial_records` VALUES (106, 1, '2025-06-19', '收入', '产品销售', 108397.76, '线下渠道销售', 'mock', 1, '2025-06-16 11:50:00');
INSERT INTO `financial_records` VALUES (107, 1, '2025-09-09', '收入', '投资收益', 10635.92, '基金收益', 'mock', 1, '2025-09-25 16:31:00');
INSERT INTO `financial_records` VALUES (108, 1, '2026-01-17', '负债', '应付工资', 86165.09, '本月应付薪资', 'mock', 1, '2026-01-14 17:43:00');
INSERT INTO `financial_records` VALUES (109, 1, '2025-08-15', '支出', '水电网络', 5042.99, '网络通信费', 'mock', 1, '2025-08-15 18:13:00');
INSERT INTO `financial_records` VALUES (110, 1, '2025-04-15', '收入', '投资收益', 18159.46, '理财产品收益', 'mock', 1, '2025-04-19 12:51:00');
INSERT INTO `financial_records` VALUES (111, 1, '2025-10-14', '支出', '软件服务', 15694.79, 'SaaS 工具订阅', 'mock', 1, '2025-10-27 17:17:00');
INSERT INTO `financial_records` VALUES (112, 1, '2026-03-04', '支出', '市场推广', 23686.83, '品牌推广费', 'mock', 1, '2026-03-22 13:34:00');
INSERT INTO `financial_records` VALUES (113, 1, '2026-01-16', '支出', '软件服务', 16077.74, '云服务器费用', 'mock', 1, '2026-01-26 12:21:00');
INSERT INTO `financial_records` VALUES (114, 1, '2025-08-06', '支出', '软件服务', 11048.36, '软件许可证', 'mock', 1, '2025-08-22 09:18:00');
INSERT INTO `financial_records` VALUES (115, 1, '2025-11-10', '负债', '短期借款', 52696.96, '信用借款', 'mock', 1, '2025-11-02 11:18:00');
INSERT INTO `financial_records` VALUES (116, 1, '2025-10-20', '收入', '咨询收入', 19290.36, '战略规划咨询', 'mock', 1, '2025-10-24 09:49:00');
INSERT INTO `financial_records` VALUES (117, 1, '2025-09-28', '资产', '固定资产', 112767.36, '办公设备', 'mock', 1, '2025-09-15 10:03:00');
INSERT INTO `financial_records` VALUES (118, 1, '2026-03-15', '负债', '应付工资', 71969.04, '社保公积金', 'mock', 1, '2026-03-21 08:03:00');
INSERT INTO `financial_records` VALUES (119, 1, '2025-11-19', '支出', '水电网络', 5657.83, '水电费', 'mock', 1, '2025-11-21 18:03:00');
INSERT INTO `financial_records` VALUES (120, 1, '2025-11-08', '资产', '银行存款', 463016.05, '建设银行账户', 'mock', 1, '2025-11-25 16:24:00');
INSERT INTO `financial_records` VALUES (121, 1, '2025-10-19', '收入', '服务收入', 38983.69, '技术支持服务', 'mock', 1, '2025-10-07 15:44:00');
INSERT INTO `financial_records` VALUES (122, 1, '2025-05-16', '资产', '银行存款', 335543.74, '建设银行账户', 'mock', 1, '2025-05-18 10:16:00');
INSERT INTO `financial_records` VALUES (123, 1, '2026-02-21', '支出', '水电网络', 6108.99, '物业管理费', 'mock', 1, '2026-02-02 12:50:00');
INSERT INTO `financial_records` VALUES (124, 1, '2025-06-04', '收入', '服务收入', 54757.48, '技术支持服务', 'mock', 1, '2025-06-22 14:22:00');
INSERT INTO `financial_records` VALUES (125, 1, '2026-02-26', '资产', '银行存款', 428460.51, '招商银行活期', 'mock', 1, '2026-02-18 13:33:00');
INSERT INTO `financial_records` VALUES (126, 1, '2025-04-09', '负债', '应付账款', 92866.08, '供应商 B 应付', 'mock', 1, '2025-04-03 11:58:00');
INSERT INTO `financial_records` VALUES (127, 1, '2025-06-14', '资产', '固定资产', 199055.28, '办公设备', 'mock', 1, '2025-06-22 17:36:00');
INSERT INTO `financial_records` VALUES (128, 1, '2025-08-23', '收入', '投资收益', 23290.28, '理财产品收益', 'mock', 1, '2025-08-14 08:33:00');
INSERT INTO `financial_records` VALUES (129, 1, '2025-11-19', '支出', '办公用品', 6334.72, '日常办公耗材', 'mock', 1, '2025-11-10 15:30:00');
INSERT INTO `financial_records` VALUES (130, 1, '2025-06-02', '支出', '软件服务', 11113.85, '云服务器费用', 'mock', 1, '2025-06-19 15:32:00');
INSERT INTO `financial_records` VALUES (131, 1, '2025-12-22', '收入', '产品销售', 137176.66, '线下渠道销售', 'mock', 1, '2025-12-26 11:27:00');
INSERT INTO `financial_records` VALUES (132, 1, '2025-12-09', '收入', '服务收入', 39175.31, '运维服务费', 'mock', 1, '2025-12-27 10:04:00');
INSERT INTO `financial_records` VALUES (133, 1, '2025-07-06', '支出', '市场推广', 16128.38, '品牌推广费', 'mock', 1, '2025-07-24 15:35:00');
INSERT INTO `financial_records` VALUES (134, 1, '2025-11-04', '支出', '人员工资', 119685.45, '行政团队薪资', 'mock', 1, '2025-11-27 11:18:00');
INSERT INTO `financial_records` VALUES (135, 1, '2026-01-17', '收入', '产品销售', 126257.37, 'C 产品线销售', 'mock', 1, '2026-01-23 12:26:00');
INSERT INTO `financial_records` VALUES (136, 1, '2025-07-05', '收入', '投资收益', 7138.22, '基金收益', 'mock', 1, '2025-07-09 12:38:00');
INSERT INTO `financial_records` VALUES (137, 1, '2026-02-20', '支出', '市场推广', 26578.56, '线上广告投放', 'mock', 1, '2026-02-24 15:53:00');
INSERT INTO `financial_records` VALUES (138, 1, '2025-05-08', '支出', '水电网络', 3270.15, '网络通信费', 'mock', 1, '2025-05-02 11:56:00');
INSERT INTO `financial_records` VALUES (139, 1, '2025-12-24', '收入', '咨询收入', 14475.77, '战略规划咨询', 'mock', 1, '2025-12-27 17:58:00');
INSERT INTO `financial_records` VALUES (140, 1, '2025-08-03', '资产', '银行存款', 375714.79, '工商银行定期', 'mock', 1, '2025-08-27 11:43:00');
INSERT INTO `financial_records` VALUES (141, 1, '2025-08-24', '支出', '办公租金', 25597.70, '总部办公室租金', 'mock', 1, '2025-08-10 16:19:00');
INSERT INTO `financial_records` VALUES (142, 1, '2025-04-11', '资产', '固定资产', 230596.86, '办公家具', 'mock', 1, '2025-04-27 08:14:00');
INSERT INTO `financial_records` VALUES (143, 1, '2025-10-12', '支出', '市场推广', 29441.22, '线上广告投放', 'mock', 1, '2025-10-18 14:42:00');
INSERT INTO `financial_records` VALUES (144, 1, '2025-09-05', '支出', '办公租金', 20593.61, '总部办公室租金', 'mock', 1, '2025-09-05 11:24:00');
INSERT INTO `financial_records` VALUES (145, 1, '2026-01-28', '资产', '银行存款', 406334.62, '招商银行活期', 'mock', 1, '2026-01-11 18:54:00');
INSERT INTO `financial_records` VALUES (146, 1, '2025-05-01', '负债', '应付账款', 36642.92, '供应商 B 应付', 'mock', 1, '2025-05-19 16:14:00');
INSERT INTO `financial_records` VALUES (147, 1, '2025-08-02', '负债', '应付工资', 116087.56, '社保公积金', 'mock', 1, '2025-08-18 11:58:00');
INSERT INTO `financial_records` VALUES (148, 1, '2025-04-07', '负债', '短期借款', 205846.55, '信用借款', 'mock', 1, '2025-04-21 15:25:00');
INSERT INTO `financial_records` VALUES (149, 1, '2025-12-19', '支出', '市场推广', 39405.74, '品牌推广费', 'mock', 1, '2025-12-02 10:30:00');
INSERT INTO `financial_records` VALUES (150, 1, '2025-05-22', '负债', '应付工资', 80692.13, '社保公积金', 'mock', 1, '2025-05-16 11:34:00');
INSERT INTO `financial_records` VALUES (151, 1, '2026-03-19', '资产', '固定资产', 118531.21, '办公设备', 'mock', 1, '2026-03-11 08:11:00');
INSERT INTO `financial_records` VALUES (152, 1, '2026-03-18', '收入', '产品销售', 195275.71, '线下渠道销售', 'mock', 1, '2026-03-11 17:14:00');
INSERT INTO `financial_records` VALUES (153, 1, '2026-02-08', '收入', '服务收入', 76952.16, '运维服务费', 'mock', 1, '2026-02-15 18:16:00');
INSERT INTO `financial_records` VALUES (154, 1, '2025-12-16', '负债', '应付账款', 99762.85, '原材料应付', 'mock', 1, '2025-12-04 08:40:00');
INSERT INTO `financial_records` VALUES (155, 1, '2025-05-25', '支出', '人员工资', 107851.35, '行政团队薪资', 'mock', 1, '2025-05-21 13:07:00');
INSERT INTO `financial_records` VALUES (156, 1, '2025-12-06', '负债', '银行贷款', 31977.77, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (157, 1, '2025-12-16', '支出', '房租', 5417.07, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (158, 1, '2026-02-05', '负债', '短期借款', 71482.11, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (159, 1, '2026-01-07', '支出', '房租', 13942.27, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (160, 1, '2025-11-06', '负债', '应付账款', 70015.66, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (161, 1, '2025-12-30', '资产', '银行存款增加', 45994.86, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (162, 1, '2025-09-20', '负债', '应付账款', 98888.65, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (163, 1, '2025-11-17', '负债', '短期借款', 32508.84, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (164, 1, '2025-11-18', '支出', '差旅费', 25629.40, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (165, 1, '2025-09-29', '支出', '差旅费', 17243.30, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (166, 1, '2026-01-27', '资产', '银行存款增加', 27142.31, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (167, 1, '2026-02-17', '负债', '应付账款', 10728.82, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (168, 1, '2026-02-24', '收入', '项目回款', 37768.26, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (169, 1, '2025-11-14', '支出', '市场推广', 24097.57, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (170, 1, '2025-10-28', '支出', '市场推广', 7668.68, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (171, 1, '2026-02-17', '支出', '水电费', 3095.49, '支付水电费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (172, 1, '2026-02-09', '收入', '咨询收入', 39853.30, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (173, 1, '2025-09-10', '资产', '银行存款增加', 14855.89, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (174, 1, '2025-11-16', '资产', '银行存款增加', 36162.73, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (175, 1, '2025-10-23', '支出', '市场推广', 26318.53, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (176, 1, '2025-12-04', '资产', '设备购置', 24272.76, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (177, 1, '2026-01-03', '资产', '银行存款增加', 70279.77, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (178, 1, '2025-10-01', '负债', '银行贷款', 22668.13, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (179, 1, '2025-10-29', '负债', '短期借款', 42919.75, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (180, 1, '2025-12-12', '收入', '咨询收入', 27755.47, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (181, 1, '2025-12-27', '资产', '银行存款增加', 61175.87, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (182, 1, '2025-11-08', '负债', '短期借款', 94626.27, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (183, 1, '2025-09-29', '支出', '差旅费', 945.73, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (184, 1, '2026-01-23', '资产', '银行存款增加', 21602.54, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (185, 1, '2025-09-18', '负债', '短期借款', 37197.12, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (186, 1, '2025-12-15', '收入', '服务收入', 4176.65, '提供技术服务收入', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (187, 1, '2025-09-11', '资产', '库存增加', 13709.04, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (188, 1, '2025-11-01', '支出', '差旅费', 13718.58, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (189, 1, '2026-02-20', '负债', '短期借款', 76804.21, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (190, 1, '2025-10-11', '负债', '短期借款', 18911.95, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (191, 1, '2026-01-05', '负债', '应付账款', 12944.47, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (192, 1, '2025-12-05', '支出', '差旅费', 13451.94, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (193, 1, '2025-11-01', '资产', '设备购置', 78569.58, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (194, 1, '2025-12-05', '资产', '设备购置', 34860.47, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (195, 1, '2025-10-20', '收入', '利息收入', 6400.32, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (196, 1, '2025-10-26', '收入', '产品销售', 39766.14, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (197, 1, '2025-11-03', '支出', '市场推广', 6315.13, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (198, 1, '2026-01-21', '支出', '市场推广', 6635.35, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (199, 1, '2025-10-31', '资产', '设备购置', 64148.28, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (200, 1, '2026-02-01', '收入', '咨询收入', 43203.49, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (201, 1, '2025-10-09', '支出', '市场推广', 7669.50, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (202, 1, '2025-10-16', '收入', '产品销售', 8326.56, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (203, 1, '2025-12-02', '支出', '市场推广', 9848.39, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (204, 1, '2025-10-16', '资产', '设备购置', 14506.89, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (205, 1, '2025-12-18', '收入', '产品销售', 24859.81, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (206, 1, '2025-12-03', '收入', '利息收入', 26184.26, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (207, 1, '2026-02-06', '收入', '项目回款', 16478.26, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (208, 1, '2026-02-13', '收入', '产品销售', 49932.16, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (209, 1, '2025-12-13', '负债', '短期借款', 19716.56, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (210, 1, '2025-12-24', '收入', '产品销售', 17461.37, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (211, 1, '2025-10-09', '收入', '服务收入', 15200.77, '提供技术服务收入', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (212, 1, '2026-02-11', '资产', '库存增加', 79597.08, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (213, 1, '2026-01-15', '资产', '库存增加', 42916.33, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (214, 1, '2025-12-21', '收入', '产品销售', 42934.05, '客户采购公司产品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (215, 1, '2026-02-15', '支出', '差旅费', 13656.34, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (216, 1, '2025-10-30', '负债', '应付账款', 84467.73, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (217, 1, '2025-12-13', '负债', '短期借款', 18557.73, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (218, 1, '2025-12-20', '资产', '银行存款增加', 24116.73, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (219, 1, '2025-10-11', '负债', '银行贷款', 18210.23, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (220, 1, '2025-09-23', '收入', '利息收入', 6635.09, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (221, 1, '2025-12-06', '支出', '市场推广', 1987.43, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (222, 1, '2026-01-23', '资产', '银行存款增加', 14167.35, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (223, 1, '2025-12-01', '负债', '短期借款', 14630.15, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (224, 1, '2025-11-14', '资产', '库存增加', 12770.04, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (225, 1, '2026-01-09', '支出', '房租', 19770.74, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (226, 1, '2025-10-29', '收入', '咨询收入', 42577.92, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (227, 1, '2025-12-05', '收入', '咨询收入', 29556.80, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (228, 1, '2025-12-20', '收入', '项目回款', 46596.05, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (229, 1, '2026-02-26', '资产', '设备购置', 18531.21, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (230, 1, '2026-02-28', '资产', '库存增加', 31326.76, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (231, 1, '2025-10-18', '支出', '市场推广', 19788.87, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (232, 1, '2025-09-19', '支出', '水电费', 19068.53, '支付水电费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (233, 1, '2025-09-09', '收入', '项目回款', 12326.38, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (234, 1, '2025-12-18', '负债', '应付账款', 24166.83, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (235, 1, '2025-11-20', '资产', '银行存款增加', 49716.78, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (236, 1, '2025-09-15', '支出', '房租', 22682.19, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (237, 1, '2025-09-14', '收入', '咨询收入', 23269.42, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (238, 1, '2025-12-19', '负债', '短期借款', 49783.98, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (239, 1, '2025-11-10', '支出', '市场推广', 3591.76, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (240, 1, '2025-12-21', '收入', '咨询收入', 34554.46, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (241, 1, '2026-01-31', '负债', '短期借款', 70041.93, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (242, 1, '2025-09-13', '支出', '差旅费', 29536.48, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (243, 1, '2025-09-16', '收入', '服务收入', 16468.13, '提供技术服务收入', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (244, 1, '2025-10-26', '支出', '员工工资', 8825.52, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (245, 1, '2025-10-02', '收入', '利息收入', 37856.68, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (246, 1, '2025-10-16', '支出', '差旅费', 16070.95, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (247, 1, '2025-10-30', '资产', '设备购置', 34780.34, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (248, 1, '2025-09-12', '负债', '银行贷款', 51377.88, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (249, 1, '2025-09-21', '资产', '银行存款增加', 37196.32, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (250, 1, '2025-12-14', '负债', '应付账款', 20365.60, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (251, 1, '2025-09-07', '资产', '设备购置', 65099.16, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (252, 1, '2026-02-07', '负债', '短期借款', 92779.28, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (253, 1, '2025-09-24', '负债', '银行贷款', 31898.48, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (254, 1, '2026-01-30', '负债', '短期借款', 17078.24, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (255, 1, '2025-11-20', '资产', '设备购置', 29980.15, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (256, 1, '2025-10-15', '收入', '项目回款', 32394.78, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (257, 1, '2026-01-15', '支出', '员工工资', 10662.77, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (258, 1, '2026-02-14', '支出', '房租', 3263.57, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (259, 1, '2025-11-06', '支出', '房租', 18151.49, '支付办公场地租金', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (260, 1, '2026-02-16', '收入', '服务收入', 47662.02, '提供技术服务收入', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (261, 1, '2026-02-09', '负债', '应付账款', 77900.12, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (262, 1, '2026-01-28', '负债', '短期借款', 93173.88, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (263, 1, '2026-01-24', '资产', '银行存款增加', 28710.42, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (264, 1, '2025-12-23', '收入', '利息收入', 23225.99, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (265, 1, '2025-11-18', '资产', '银行存款增加', 9212.91, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (266, 1, '2026-01-09', '收入', '咨询收入', 24163.64, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (267, 1, '2025-09-11', '收入', '咨询收入', 41921.44, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (268, 1, '2025-09-21', '收入', '项目回款', 30515.83, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (269, 1, '2025-12-09', '负债', '短期借款', 59888.47, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (270, 1, '2025-09-12', '负债', '短期借款', 68665.37, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (271, 1, '2025-11-23', '负债', '短期借款', 23577.50, '短期资金周转借款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (272, 1, '2025-09-17', '负债', '银行贷款', 82987.01, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (273, 1, '2025-11-28', '收入', '项目回款', 33014.10, '项目阶段性回款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (274, 1, '2025-09-12', '支出', '水电费', 13245.20, '支付水电费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (275, 1, '2025-12-23', '支出', '员工工资', 11310.99, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (276, 1, '2025-11-13', '负债', '应付账款', 79701.83, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (277, 1, '2026-02-22', '收入', '咨询收入', 5163.77, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (278, 1, '2025-09-26', '负债', '应付账款', 32679.62, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (279, 1, '2026-02-17', '支出', '员工工资', 2628.76, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (280, 1, '2026-02-18', '支出', '员工工资', 9444.91, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (281, 1, '2026-02-16', '负债', '银行贷款', 63553.71, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (282, 1, '2025-09-23', '资产', '银行存款增加', 33250.95, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (283, 1, '2025-11-25', '支出', '水电费', 21144.36, '支付水电费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (284, 1, '2026-02-24', '收入', '利息收入', 26407.45, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (285, 1, '2025-09-06', '资产', '库存增加', 18519.72, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (286, 1, '2025-10-26', '资产', '库存增加', 19400.39, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (287, 1, '2025-10-07', '支出', '办公用品', 9014.60, '采购办公耗材', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (288, 1, '2025-09-27', '收入', '咨询收入', 44066.85, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (289, 1, '2026-02-07', '支出', '市场推广', 11426.25, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (290, 1, '2025-10-13', '支出', '水电费', 23178.71, '支付水电费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (291, 1, '2025-10-14', '负债', '银行贷款', 46977.28, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (292, 1, '2026-02-22', '支出', '差旅费', 18395.74, '员工出差报销', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (293, 1, '2025-12-25', '支出', '市场推广', 7327.22, '线上推广费用', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (294, 1, '2025-12-31', '支出', '员工工资', 20413.54, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (295, 1, '2026-01-26', '负债', '应付账款', 79249.47, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (296, 1, '2025-12-08', '负债', '银行贷款', 83520.21, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (297, 1, '2026-02-03', '支出', '员工工资', 1754.96, '发放员工工资', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (298, 1, '2026-01-03', '资产', '银行存款增加', 75072.02, '公司账户存款增加', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (299, 1, '2026-01-12', '收入', '咨询收入', 6026.01, '管理咨询服务费', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (300, 1, '2025-10-13', '资产', '库存增加', 72897.97, '采购库存商品', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (301, 1, '2025-10-09', '负债', '银行贷款', 95177.19, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (302, 1, '2025-10-28', '负债', '应付账款', 93742.47, '供应商应付款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (303, 1, '2025-12-17', '收入', '利息收入', 26096.34, '银行存款利息', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (304, 1, '2025-11-01', '负债', '银行贷款', 43742.14, '新增银行贷款', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (305, 1, '2025-09-09', '资产', '设备购置', 67938.22, '购入办公设备', 'excel_import', 1, '2026-03-01 12:20:09');
INSERT INTO `financial_records` VALUES (306, 888888888, '2025-12-06', '负债', '银行贷款', 31977.77, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (307, 888888888, '2025-12-16', '支出', '房租', 5417.07, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (308, 888888888, '2026-02-05', '负债', '短期借款', 71482.11, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (309, 888888888, '2026-01-07', '支出', '房租', 13942.27, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (310, 888888888, '2025-11-06', '负债', '应付账款', 70015.66, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (311, 888888888, '2025-12-30', '资产', '银行存款增加', 45994.86, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (312, 888888888, '2025-09-20', '负债', '应付账款', 98888.65, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (313, 888888888, '2025-11-17', '负债', '短期借款', 32508.84, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (314, 888888888, '2025-11-18', '支出', '差旅费', 25629.40, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (315, 888888888, '2025-09-29', '支出', '差旅费', 17243.30, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (316, 888888888, '2026-01-27', '资产', '银行存款增加', 27142.31, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (317, 888888888, '2026-02-17', '负债', '应付账款', 10728.82, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (318, 888888888, '2026-02-24', '收入', '项目回款', 37768.26, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (319, 888888888, '2025-11-14', '支出', '市场推广', 24097.57, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (320, 888888888, '2025-10-28', '支出', '市场推广', 7668.68, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (321, 888888888, '2026-02-17', '支出', '水电费', 3095.49, '支付水电费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (322, 888888888, '2026-02-09', '收入', '咨询收入', 39853.30, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (323, 888888888, '2025-09-10', '资产', '银行存款增加', 14855.89, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (324, 888888888, '2025-11-16', '资产', '银行存款增加', 36162.73, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (325, 888888888, '2025-10-23', '支出', '市场推广', 26318.53, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (326, 888888888, '2025-12-04', '资产', '设备购置', 24272.76, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (327, 888888888, '2026-01-03', '资产', '银行存款增加', 70279.77, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (328, 888888888, '2025-10-01', '负债', '银行贷款', 22668.13, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (329, 888888888, '2025-10-29', '负债', '短期借款', 42919.75, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (330, 888888888, '2025-12-12', '收入', '咨询收入', 27755.47, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (331, 888888888, '2025-12-27', '资产', '银行存款增加', 61175.87, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (332, 888888888, '2025-11-08', '负债', '短期借款', 94626.27, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (333, 888888888, '2025-09-29', '支出', '差旅费', 945.73, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (334, 888888888, '2026-01-23', '资产', '银行存款增加', 21602.54, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (335, 888888888, '2025-09-18', '负债', '短期借款', 37197.12, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (336, 888888888, '2025-12-15', '收入', '服务收入', 4176.65, '提供技术服务收入', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (337, 888888888, '2025-09-11', '资产', '库存增加', 13709.04, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (338, 888888888, '2025-11-01', '支出', '差旅费', 13718.58, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (339, 888888888, '2026-02-20', '负债', '短期借款', 76804.21, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (340, 888888888, '2025-10-11', '负债', '短期借款', 18911.95, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (341, 888888888, '2026-01-05', '负债', '应付账款', 12944.47, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (342, 888888888, '2025-12-05', '支出', '差旅费', 13451.94, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (343, 888888888, '2025-11-01', '资产', '设备购置', 78569.58, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (344, 888888888, '2025-12-05', '资产', '设备购置', 34860.47, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (345, 888888888, '2025-10-20', '收入', '利息收入', 6400.32, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (346, 888888888, '2025-10-26', '收入', '产品销售', 39766.14, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (347, 888888888, '2025-11-03', '支出', '市场推广', 6315.13, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (348, 888888888, '2026-01-21', '支出', '市场推广', 6635.35, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (349, 888888888, '2025-10-31', '资产', '设备购置', 64148.28, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (350, 888888888, '2026-02-01', '收入', '咨询收入', 43203.49, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (351, 888888888, '2025-10-09', '支出', '市场推广', 7669.50, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (352, 888888888, '2025-10-16', '收入', '产品销售', 8326.56, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (353, 888888888, '2025-12-02', '支出', '市场推广', 9848.39, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (354, 888888888, '2025-10-16', '资产', '设备购置', 14506.89, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (355, 888888888, '2025-12-18', '收入', '产品销售', 24859.81, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (356, 888888888, '2025-12-03', '收入', '利息收入', 26184.26, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (357, 888888888, '2026-02-06', '收入', '项目回款', 16478.26, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (358, 888888888, '2026-02-13', '收入', '产品销售', 49932.16, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (359, 888888888, '2025-12-13', '负债', '短期借款', 19716.56, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (360, 888888888, '2025-12-24', '收入', '产品销售', 17461.37, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (361, 888888888, '2025-10-09', '收入', '服务收入', 15200.77, '提供技术服务收入', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (362, 888888888, '2026-02-11', '资产', '库存增加', 79597.08, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (363, 888888888, '2026-01-15', '资产', '库存增加', 42916.33, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (364, 888888888, '2025-12-21', '收入', '产品销售', 42934.05, '客户采购公司产品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (365, 888888888, '2026-02-15', '支出', '差旅费', 13656.34, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (366, 888888888, '2025-10-30', '负债', '应付账款', 84467.73, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (367, 888888888, '2025-12-13', '负债', '短期借款', 18557.73, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (368, 888888888, '2025-12-20', '资产', '银行存款增加', 24116.73, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (369, 888888888, '2025-10-11', '负债', '银行贷款', 18210.23, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (370, 888888888, '2025-09-23', '收入', '利息收入', 6635.09, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (371, 888888888, '2025-12-06', '支出', '市场推广', 1987.43, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (372, 888888888, '2026-01-23', '资产', '银行存款增加', 14167.35, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (373, 888888888, '2025-12-01', '负债', '短期借款', 14630.15, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (374, 888888888, '2025-11-14', '资产', '库存增加', 12770.04, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (375, 888888888, '2026-01-09', '支出', '房租', 19770.74, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (376, 888888888, '2025-10-29', '收入', '咨询收入', 42577.92, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (377, 888888888, '2025-12-05', '收入', '咨询收入', 29556.80, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (378, 888888888, '2025-12-20', '收入', '项目回款', 46596.05, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (379, 888888888, '2026-02-26', '资产', '设备购置', 18531.21, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (380, 888888888, '2026-02-28', '资产', '库存增加', 31326.76, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (381, 888888888, '2025-10-18', '支出', '市场推广', 19788.87, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (382, 888888888, '2025-09-19', '支出', '水电费', 19068.53, '支付水电费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (383, 888888888, '2025-09-09', '收入', '项目回款', 12326.38, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (384, 888888888, '2025-12-18', '负债', '应付账款', 24166.83, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (385, 888888888, '2025-11-20', '资产', '银行存款增加', 49716.78, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (386, 888888888, '2025-09-15', '支出', '房租', 22682.19, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (387, 888888888, '2025-09-14', '收入', '咨询收入', 23269.42, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (388, 888888888, '2025-12-19', '负债', '短期借款', 49783.98, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (389, 888888888, '2025-11-10', '支出', '市场推广', 3591.76, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (390, 888888888, '2025-12-21', '收入', '咨询收入', 34554.46, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (391, 888888888, '2026-01-31', '负债', '短期借款', 70041.93, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (392, 888888888, '2025-09-13', '支出', '差旅费', 29536.48, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (393, 888888888, '2025-09-16', '收入', '服务收入', 16468.13, '提供技术服务收入', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (394, 888888888, '2025-10-26', '支出', '员工工资', 8825.52, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (395, 888888888, '2025-10-02', '收入', '利息收入', 37856.68, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (396, 888888888, '2025-10-16', '支出', '差旅费', 16070.95, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (397, 888888888, '2025-10-30', '资产', '设备购置', 34780.34, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (398, 888888888, '2025-09-12', '负债', '银行贷款', 51377.88, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (399, 888888888, '2025-09-21', '资产', '银行存款增加', 37196.32, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (400, 888888888, '2025-12-14', '负债', '应付账款', 20365.60, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (401, 888888888, '2025-09-07', '资产', '设备购置', 65099.16, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (402, 888888888, '2026-02-07', '负债', '短期借款', 92779.28, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (403, 888888888, '2025-09-24', '负债', '银行贷款', 31898.48, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (404, 888888888, '2026-01-30', '负债', '短期借款', 17078.24, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (405, 888888888, '2025-11-20', '资产', '设备购置', 29980.15, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (406, 888888888, '2025-10-15', '收入', '项目回款', 32394.78, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (407, 888888888, '2026-01-15', '支出', '员工工资', 10662.77, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (408, 888888888, '2026-02-14', '支出', '房租', 3263.57, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (409, 888888888, '2025-11-06', '支出', '房租', 18151.49, '支付办公场地租金', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (410, 888888888, '2026-02-16', '收入', '服务收入', 47662.02, '提供技术服务收入', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (411, 888888888, '2026-02-09', '负债', '应付账款', 77900.12, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (412, 888888888, '2026-01-28', '负债', '短期借款', 93173.88, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (413, 888888888, '2026-01-24', '资产', '银行存款增加', 28710.42, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (414, 888888888, '2025-12-23', '收入', '利息收入', 23225.99, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (415, 888888888, '2025-11-18', '资产', '银行存款增加', 9212.91, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (416, 888888888, '2026-01-09', '收入', '咨询收入', 24163.64, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (417, 888888888, '2025-09-11', '收入', '咨询收入', 41921.44, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (418, 888888888, '2025-09-21', '收入', '项目回款', 30515.83, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (419, 888888888, '2025-12-09', '负债', '短期借款', 59888.47, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (420, 888888888, '2025-09-12', '负债', '短期借款', 68665.37, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (421, 888888888, '2025-11-23', '负债', '短期借款', 23577.50, '短期资金周转借款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (422, 888888888, '2025-09-17', '负债', '银行贷款', 82987.01, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (423, 888888888, '2025-11-28', '收入', '项目回款', 33014.10, '项目阶段性回款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (424, 888888888, '2025-09-12', '支出', '水电费', 13245.20, '支付水电费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (425, 888888888, '2025-12-23', '支出', '员工工资', 11310.99, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (426, 888888888, '2025-11-13', '负债', '应付账款', 79701.83, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (427, 888888888, '2026-02-22', '收入', '咨询收入', 5163.77, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (428, 888888888, '2025-09-26', '负债', '应付账款', 32679.62, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (429, 888888888, '2026-02-17', '支出', '员工工资', 2628.76, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (430, 888888888, '2026-02-18', '支出', '员工工资', 9444.91, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (431, 888888888, '2026-02-16', '负债', '银行贷款', 63553.71, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (432, 888888888, '2025-09-23', '资产', '银行存款增加', 33250.95, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (433, 888888888, '2025-11-25', '支出', '水电费', 21144.36, '支付水电费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (434, 888888888, '2026-02-24', '收入', '利息收入', 26407.45, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (435, 888888888, '2025-09-06', '资产', '库存增加', 18519.72, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (436, 888888888, '2025-10-26', '资产', '库存增加', 19400.39, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (437, 888888888, '2025-10-07', '支出', '办公用品', 9014.60, '采购办公耗材', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (438, 888888888, '2025-09-27', '收入', '咨询收入', 44066.85, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (439, 888888888, '2026-02-07', '支出', '市场推广', 11426.25, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (440, 888888888, '2025-10-13', '支出', '水电费', 23178.71, '支付水电费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (441, 888888888, '2025-10-14', '负债', '银行贷款', 46977.28, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (442, 888888888, '2026-02-22', '支出', '差旅费', 18395.74, '员工出差报销', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (443, 888888888, '2025-12-25', '支出', '市场推广', 7327.22, '线上推广费用', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (444, 888888888, '2025-12-31', '支出', '员工工资', 20413.54, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (445, 888888888, '2026-01-26', '负债', '应付账款', 79249.47, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (446, 888888888, '2025-12-08', '负债', '银行贷款', 83520.21, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (447, 888888888, '2026-02-03', '支出', '员工工资', 1754.96, '发放员工工资', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (448, 888888888, '2026-01-03', '资产', '银行存款增加', 75072.02, '公司账户存款增加', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (449, 888888888, '2026-01-12', '收入', '咨询收入', 6026.01, '管理咨询服务费', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (450, 888888888, '2025-10-13', '资产', '库存增加', 72897.97, '采购库存商品', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (451, 888888888, '2025-10-09', '负债', '银行贷款', 95177.19, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (452, 888888888, '2025-10-28', '负债', '应付账款', 93742.47, '供应商应付款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (453, 888888888, '2025-12-17', '收入', '利息收入', 26096.34, '银行存款利息', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (454, 888888888, '2025-11-01', '负债', '银行贷款', 43742.14, '新增银行贷款', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (455, 888888888, '2025-09-09', '资产', '设备购置', 67938.22, '购入办公设备', 'excel_import', 1, '2026-03-01 15:43:15');
INSERT INTO `financial_records` VALUES (456, 888888888, '2026-03-01', '支出', '差旅费', 85555.00, '出差报销专用', 'manual', 1, '2026-03-02 06:37:59');
INSERT INTO `financial_records` VALUES (457, 888888888, '2026-03-02', '资产', '资产变现', 5999999.00, '资产变现', 'manual', 1, '2026-03-02 06:38:35');

-- ----------------------------
-- Table structure for reports
-- ----------------------------
DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `company_id` int NOT NULL,
  `report_type` enum('profit_loss','balance_sheet','cash_flow') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `data_json` json NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_reports_company_created_at`(`company_id` ASC, `created_at` ASC) USING BTREE,
  INDEX `idx_reports_company_type_period`(`company_id` ASC, `report_type` ASC, `period_start` ASC, `period_end` ASC) USING BTREE,
  CONSTRAINT `fk_reports_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_reports_period_valid` CHECK (`period_end` >= `period_start`)
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of reports
-- ----------------------------
INSERT INTO `reports` VALUES (1, 1, 'profit_loss', '利润表 (2026-03-01 ~ 2026-03-01)', '2026-03-01', '2026-03-01', '{\"净利润\": 0, \"支出合计\": 0, \"支出明细\": {}, \"收入合计\": 0, \"收入明细\": {}}', '2026-03-01 06:28:23');
INSERT INTO `reports` VALUES (2, 1, 'cash_flow', '现金流量表 (2026-03-01 ~ 2026-03-02)', '2026-03-01', '2026-03-02', '{\"净现金流\": 18999.0, \"流入合计\": 18999.0, \"流出合计\": 0, \"现金流入\": {\"销售收入\": 18999.0}, \"现金流出\": {}}', '2026-03-01 07:08:30');
INSERT INTO `reports` VALUES (3, 1, 'profit_loss', '利润表 (2026-03-01 ~ 2026-03-02)', '2026-03-01', '2026-03-02', '{\"净利润\": 18999.0, \"支出合计\": 0, \"支出明细\": {}, \"收入合计\": 18999.0, \"收入明细\": {\"销售收入\": 18999.0}}', '2026-03-01 07:08:45');
INSERT INTO `reports` VALUES (4, 1, 'profit_loss', '利润表 (2026-03-01 ~ 2026-03-02)', '2026-03-01', '2026-03-02', '{\"净利润\": -81001.0, \"支出合计\": 100000.0, \"支出明细\": {\"购买物料\": 100000.0}, \"收入合计\": 18999.0, \"收入明细\": {\"销售收入\": 18999.0}}', '2026-03-01 07:14:21');
INSERT INTO `reports` VALUES (5, 1, 'profit_loss', '利润表 (2025-12-01 ~ 2026-03-01)', '2025-12-01', '2026-03-01', '{\"AI分析\": {\"摘要\": \"收入在报表期间下降 96.2%，变化幅度较大；支出基本持平；期间利润率为 55.9%。\", \"趋势\": [{\"变化\": \"-96.2%\", \"月均\": 321178.65, \"期初\": 505785.96, \"期末\": 18999.0, \"类别\": \"收入\"}, {\"变化\": \"+1.9%\", \"月均\": 141675.56, \"期初\": 147239.63, \"期末\": 150000.0, \"类别\": \"支出\"}], \"异常项\": []}, \"净利润\": 718012.3400000001, \"支出合计\": 566702.25, \"支出明细\": {\"工资\": 50000.0, \"房租\": 42393.65, \"差旅费\": 45504.02, \"水电费\": 3095.49, \"人员工资\": 67400.38, \"办公用品\": 13206.9, \"员工工资\": 56215.93000000001, \"差旅费用\": 35331.51, \"市场推广\": 103208.94, \"水电网络\": 11821.48, \"购买物料\": 100000.0, \"软件服务\": 38523.95}, \"收入合计\": 1284714.59, \"收入明细\": {\"产品销售\": 594875.43, \"利息收入\": 101914.04, \"咨询收入\": 254249.72999999995, \"投资收益\": 45867.68, \"服务收入\": 167966.13999999998, \"销售收入\": 18999.0, \"项目回款\": 100842.57}}', '2026-03-01 12:25:11');
INSERT INTO `reports` VALUES (6, 888888888, 'profit_loss', '利润表 (2025-12-01 ~ 2026-03-02)', '2025-12-01', '2026-03-02', '{\"AI分析\": {\"摘要\": \"收入小幅下降 12.2%；支出小幅下降 8.7%；期间利润率为 69.3%。\", \"趋势\": [{\"变化\": \"-12.2%\", \"月均\": 200019.87, \"期初\": 303401.25, \"期末\": 266468.71, \"类别\": \"收入\"}, {\"变化\": \"-8.7%\", \"月均\": 61477.91, \"期初\": 69756.58, \"期末\": 63666.02, \"类别\": \"支出\"}], \"异常项\": []}, \"净利润\": 415625.88, \"支出合计\": 184433.73, \"支出明细\": {\"房租\": 42393.65, \"差旅费\": 45504.02, \"水电费\": 3095.49, \"员工工资\": 56215.93000000001, \"市场推广\": 37224.64}, \"收入合计\": 600059.61, \"收入明细\": {\"产品销售\": 135187.39, \"利息收入\": 101914.04, \"咨询收入\": 210276.93999999997, \"服务收入\": 51838.67, \"项目回款\": 100842.57}}', '2026-03-02 05:40:01');
INSERT INTO `reports` VALUES (7, 888888888, 'balance_sheet', '资产负债表 (2025-01-01 ~ 2026-03-02)', '2025-01-01', '2026-03-02', '{\"AI分析\": {\"摘要\": \"资产在报表期间增长 2294.5%，变化幅度较大；负债在报表期间下降 100.0%，变化幅度较大；资产负债率为 29.7%；共发现 2 处异常波动。\", \"趋势\": [{\"变化\": \"+2294.5%\", \"月均\": 1038925.83, \"期初\": 250569.3, \"期末\": 5999999.0, \"类别\": \"资产\"}, {\"变化\": \"-100.0%\", \"月均\": 308469.23, \"期初\": 403694.13, \"期末\": 0, \"类别\": \"负债\"}], \"异常项\": [{\"月份\": \"2026-03\", \"类别\": \"资产\", \"金额\": 5999999.0, \"偏离程度\": \"偏高 2.4 个标准差\"}, {\"月份\": \"2026-03\", \"类别\": \"负债\", \"金额\": 0, \"偏离程度\": \"偏低 2.3 个标准差\"}]}, \"负债合计\": 2159284.64, \"负债明细\": {\"应付账款\": 684851.2699999999, \"短期借款\": 902343.34, \"银行贷款\": 572090.03}, \"资产合计\": 7272480.84, \"资产明细\": {\"库存增加\": 291137.33, \"设备购置\": 432687.0600000001, \"资产变现\": 5999999.0, \"银行存款增加\": 548657.4500000001}, \"所有者权益\": 5113196.199999999}', '2026-03-02 07:50:32');
INSERT INTO `reports` VALUES (8, 888888888, 'cash_flow', '现金流量表 (2026-01-01 ~ 2026-03-02)', '2026-01-01', '2026-03-02', '{\"AI分析\": {\"摘要\": \"收入在报表期间下降 100.0%，变化幅度较大；支出在报表期间增长 67.7%，变化幅度较大。\", \"趋势\": [{\"变化\": \"-100.0%\", \"月均\": 98886.12, \"期初\": 30189.65, \"期末\": 0, \"类别\": \"收入\"}, {\"变化\": \"+67.7%\", \"月均\": 66744.05, \"期初\": 51011.13, \"期末\": 85555.0, \"类别\": \"支出\"}], \"异常项\": []}, \"净现金流\": 96426.21000000004, \"流入合计\": 296658.36000000004, \"流出合计\": 200232.15, \"现金流入\": {\"产品销售\": 49932.16, \"利息收入\": 26407.45, \"咨询收入\": 118410.21, \"服务收入\": 47662.02, \"项目回款\": 54246.52}, \"现金流出\": {\"房租\": 36976.58, \"差旅费\": 117607.08, \"水电费\": 3095.49, \"员工工资\": 24491.4, \"市场推广\": 18061.6}}', '2026-03-02 07:50:50');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `hashed_password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','accountant','viewer') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'viewer',
  `company_id` int NULL DEFAULT NULL,
  `company_super_admin` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ix_users_username`(`username` ASC) USING BTREE,
  UNIQUE INDEX `ix_users_email`(`email` ASC) USING BTREE,
  INDEX `idx_users_company_role`(`company_id` ASC, `role` ASC) USING BTREE,
  INDEX `idx_users_company_super_admin`(`company_id` ASC, `company_super_admin` ASC) USING BTREE,
  CONSTRAINT `fk_users_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_users_company_super_admin` CHECK (`company_super_admin` in (0,1)),
  CONSTRAINT `chk_users_is_active` CHECK (`is_active` in (0,1))
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin', '898398828@qq.com', '$2b$12$8tDsaqv/.xZppfXH9Gv2h.KRt9AmexY64SMdLju8hmq2lMwqM5QaK', 'admin', 888888888, 1, 1, '2026-03-01 06:26:00');
INSERT INTO `users` VALUES (2, 'cui91755282@gmail.com', 'cui91755282@gmail.com', '$2b$12$1pyHtpy7a7WH4PqX95XAwu6k15CHgn1KE8CQ/i.Lx1PlYU/A/u1Aa', 'accountant', 578598105, 1, 1, '2026-03-01 07:21:12');
INSERT INTO `users` VALUES (4, 'user1', 'cu232323@gmail.com', '$2b$12$gkN0xPtzCOww2pCj2qv69uuEDr8JTsqF8Bmk35U4cXan.rrUJ.fEO', 'admin', 888888888, 0, 1, '2026-03-01 07:22:11');
INSERT INTO `users` VALUES (5, 'admin123', 'cui982@gmail.com', '$2b$12$Fv05xQRQUMWv6GdEJwqp8uNvP13hLmKNS8gWtx1EPGE.fdNMBo94.', 'admin', 578598105, 0, 1, '2026-03-01 15:24:23');
INSERT INTO `users` VALUES (6, 'admin12', 'cui922@gmail.com', '$2b$12$ggkeNGYUPxTXil6cCSugh.Da/vtHhtUBeulgC/cLEmfBgxOGzl.Am', 'viewer', 888888888, 0, 1, '2026-03-02 09:04:49');

SET FOREIGN_KEY_CHECKS = 1;
