-- Schema for the three-tier demo app.
-- The backend also creates this table automatically on startup (see backend/src/db.js),
-- so this file is mainly useful for local docker-compose bootstrapping and documentation.

CREATE DATABASE IF NOT EXISTS taskdb;
USE taskdb;

CREATE TABLE IF NOT EXISTS tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status ENUM('todo', 'in_progress', 'done') NOT NULL DEFAULT 'todo',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO tasks (title, description, status) VALUES
  ('Set up VPC and subnets', 'Public + private subnets across 2 AZs', 'done'),
  ('Provision RDS MySQL', 'Multi-AZ, private subnet only', 'in_progress'),
  ('Deploy ECS Fargate services', 'Frontend + backend behind ALB', 'todo');
