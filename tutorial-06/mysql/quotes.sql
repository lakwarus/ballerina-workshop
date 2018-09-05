create database quotes;
use quotes;
create table quotes (ID int NOT NULL AUTO_INCREMENT, CATEGORY varchar(255), QUOTE text, PRIMARY KEY (ID));
ALTER TABLE quotes AUTO_INCREMENT=100;
insert into quotes (CATEGORY,QUOTE) values ('Docker','Docker allows you to package an application with all of its dependencies into a standardized unit for software development'),
('Docker','Docker eliminate the it works on my machine problem once and for all'),
('Docker','Docker ensures consistent environments from development to production'),
('Docker','Docker ensures your applications and resources are isolated and segregated'),
('Docker','Docker reduces effort and risk of problems with application dependencies'),
('K8S','A pod is a group of one or more containers, with shared storage/network, and a specification for how to run the containers'),
('K8S','A pod is a group of containers that are deployed together on the same host'),
('K8S','K8S Service is group of pods that work together'),
('K8S','K8S replication controller ensures N copies of Pod. If too few, start new one. If too many, kill some'),
('K8S','K8S configMap inject config as a virtual volume into the Pods'),
('K8S','K8S Ingress controller maps HTTP and HTTPS incoming traffic to backend services'),
('K8S','K8S HPA automatically scale replication controllers to a target utilization'),
('K8S','K8S allowing deploy containers across multiple host machine while providing scalability and high availability'),
('K8S','K8S automates rollouts and rollbacks, monitoring the health of your services to prevent bad rollouts before things go bad'),
('K8S','K8S will automatically scale your services up or down based off of utilization, ensuring you are only running what you need, when you need it');
	 
