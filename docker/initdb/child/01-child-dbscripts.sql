-- UPDATE `user` set user_password_temp = 0;
UPDATE `user` SET `user_password_changed` = "2025-10-01 00:00";
-- UPDATE `drug_lot` SET drug_lot_expiration = "2028-01-30 00:00"
-- UPDATE `company` SET company_site = CONCAT('https://', company_site) WHERE company_site NOT LIKE '%https%';

-- Grant full privileges globally
GRANT ALL PRIVILEGES ON *.* TO 'easuser'@'%' WITH GRANT OPTION;

-- Optional: Create app-specific user for security separation
-- CREATE USER IF NOT EXISTS 'eas_app'@'%' IDENTIFIED BY 'AppOnly!456';
-- GRANT ALL PRIVILEGES ON eas_v3child.* TO 'eas_app'@'%';

FLUSH PRIVILEGES;