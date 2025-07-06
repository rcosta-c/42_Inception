# 42_Inception


#lista dockers montados e estado de serviço
docker ps -a
#verificar volumes criados
docker volume ls

docker-compose -f ./srcs/docker-compose.yml up -d --build

#entrar com bash docker wordpress
docker exec -it wordpress bash

#entrar no docker mariadb
docker exec -it mariadb mysql -u root -p

#depois de entrar no mariadb, testar estes cmds
-- Ver todas as bases de dados
SHOW DATABASES;
-- Usar a base de dados do WordPress
USE nome_da_database;
-- Ver todas as tabelas
SHOW TABLES;
-- Ver utilizadores
SELECT User, Host FROM mysql.user;
-- Ver estrutura de uma tabela
DESCRIBE wp_users;
-- Sair
EXIT;