IF DB_ID(N'FinanceTrack') IS NULL CREATE DATABASE FinanceTrack;
GO
USE FinanceTrack;
GO
CREATE TABLE dbo.users (
 id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_users PRIMARY KEY,
 full_name NVARCHAR(120) NOT NULL,
 email NVARCHAR(254) NOT NULL,
 password_hash NVARCHAR(100) NOT NULL,
 enabled BIT NOT NULL CONSTRAINT DF_users_enabled DEFAULT 1,
 created_at DATETIME2 NOT NULL CONSTRAINT DF_users_created DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_users_email UNIQUE(email)
);
CREATE TABLE dbo.roles (id BIGINT IDENTITY PRIMARY KEY, name NVARCHAR(30) NOT NULL UNIQUE);
CREATE TABLE dbo.user_roles (user_id BIGINT NOT NULL, role_id BIGINT NOT NULL, CONSTRAINT PK_user_roles PRIMARY KEY(user_id,role_id), CONSTRAINT FK_user_roles_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT FK_user_roles_role FOREIGN KEY(role_id) REFERENCES dbo.roles(id));
CREATE TABLE dbo.categories (id BIGINT IDENTITY PRIMARY KEY, name NVARCHAR(60) NOT NULL, kind NVARCHAR(12) NOT NULL, system_defined BIT NOT NULL DEFAULT 1, CONSTRAINT UQ_categories_name_kind UNIQUE(name,kind), CONSTRAINT CK_categories_kind CHECK(kind IN ('INCOME','EXPENSE')));
CREATE TABLE dbo.income (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, category_id BIGINT NOT NULL, description NVARCHAR(200) NOT NULL, amount DECIMAL(19,4) NOT NULL, occurred_on DATE NOT NULL, created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), CONSTRAINT CK_income_amount CHECK(amount>0), CONSTRAINT FK_income_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT FK_income_category FOREIGN KEY(category_id) REFERENCES dbo.categories(id));
CREATE TABLE dbo.expenses (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, category_id BIGINT NOT NULL, description NVARCHAR(200) NOT NULL, amount DECIMAL(19,4) NOT NULL, occurred_on DATE NOT NULL, created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), CONSTRAINT CK_expenses_amount CHECK(amount>0), CONSTRAINT FK_expenses_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT FK_expenses_category FOREIGN KEY(category_id) REFERENCES dbo.categories(id));
CREATE TABLE dbo.budgets (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, category_id BIGINT NOT NULL, year SMALLINT NOT NULL, month TINYINT NOT NULL, amount DECIMAL(19,4) NOT NULL, CONSTRAINT CK_budgets_month CHECK(month BETWEEN 1 AND 12), CONSTRAINT CK_budgets_amount CHECK(amount>0), CONSTRAINT UQ_budgets_period UNIQUE(user_id,category_id,year,month), CONSTRAINT FK_budgets_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT FK_budgets_category FOREIGN KEY(category_id) REFERENCES dbo.categories(id));
CREATE TABLE dbo.predictions (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, target_month DATE NOT NULL, predicted_expense DECIMAL(19,4) NOT NULL, generated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), CONSTRAINT FK_predictions_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT UQ_predictions_month UNIQUE(user_id,target_month));
CREATE TABLE dbo.notifications (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, kind NVARCHAR(30) NOT NULL, message NVARCHAR(500) NOT NULL, created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(), read_at DATETIME2 NULL, CONSTRAINT FK_notifications_user FOREIGN KEY(user_id) REFERENCES dbo.users(id));
CREATE TABLE dbo.user_settings (user_id BIGINT NOT NULL CONSTRAINT PK_user_settings PRIMARY KEY, currency CHAR(3) NOT NULL DEFAULT 'USD', monthly_savings_goal DECIMAL(19,4) NULL, salary DECIMAL(19,4) NULL, CONSTRAINT FK_user_settings_user FOREIGN KEY(user_id) REFERENCES dbo.users(id), CONSTRAINT CK_settings_goal CHECK(monthly_savings_goal IS NULL OR monthly_savings_goal>=0));
CREATE TABLE dbo.refresh_tokens (id BIGINT IDENTITY PRIMARY KEY, user_id BIGINT NOT NULL, token_hash CHAR(64) NOT NULL UNIQUE, expires_at DATETIME2 NOT NULL, revoked_at DATETIME2 NULL, CONSTRAINT FK_refresh_user FOREIGN KEY(user_id) REFERENCES dbo.users(id));
CREATE INDEX IX_income_user_date ON dbo.income(user_id,occurred_on DESC);
CREATE INDEX IX_expenses_user_date ON dbo.expenses(user_id,occurred_on DESC);
CREATE INDEX IX_expenses_user_category_date ON dbo.expenses(user_id,category_id,occurred_on);
CREATE INDEX IX_budgets_user_period ON dbo.budgets(user_id,year,month);
CREATE INDEX IX_notifications_user_date ON dbo.notifications(user_id,created_at DESC);
CREATE INDEX IX_predictions_user_month ON dbo.predictions(user_id,target_month);
INSERT INTO dbo.roles(name) VALUES ('USER'),('ADMIN');
INSERT INTO dbo.categories(name,kind) VALUES
('Sueldo','INCOME'),('Freelance','INCOME'),('Bonos','INCOME'),('Inversiones','INCOME'),('Otros ingresos','INCOME'),
('Alimentación','EXPENSE'),('Transporte','EXPENSE'),('Vivienda','EXPENSE'),('Salud','EXPENSE'),('Educación','EXPENSE'),('Streaming','EXPENSE'),('Compras','EXPENSE'),('Viajes','EXPENSE'),('Servicios','EXPENSE'),('Deudas','EXPENSE'),('Entretenimiento','EXPENSE'),('Otros','EXPENSE');
GO
