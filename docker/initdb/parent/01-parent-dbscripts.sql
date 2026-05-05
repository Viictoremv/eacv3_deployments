UPDATE user
                SET auth_code = NULL,
                    totp_secret = NULL,
                    totp_enabled = NULL,
                    mail_disabled = 0
                WHERE email = 'developer@quasars.com';