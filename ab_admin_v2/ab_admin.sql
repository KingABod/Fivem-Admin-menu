CREATE TABLE IF NOT EXISTS `ab_bans` (
    `id`          INT(11)      NOT NULL AUTO_INCREMENT,
    `license`     VARCHAR(50)  NOT NULL,
    `reason`      VARCHAR(255) NOT NULL,
    `admin`       VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `expire`      INT(11)      NOT NULL DEFAULT 0,
    `date`        INT(11)      NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_license` (`license`),
    INDEX `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ab_admin_logs` (
    `id`        INT(11)      NOT NULL AUTO_INCREMENT,
    `admin`     VARCHAR(100) NOT NULL,
    `action`    VARCHAR(50)  NOT NULL,
    `target`    VARCHAR(100) DEFAULT NULL,
    `detail`    VARCHAR(255) DEFAULT NULL,
    `date`      INT(11)      NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
